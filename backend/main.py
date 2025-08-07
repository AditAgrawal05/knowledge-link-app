import os
import requests
import motor.motor_asyncio
import google.generativeai as genai
from fastapi import FastAPI, HTTPException
from fastapi.middleware.cors import CORSMiddleware
from pydantic import BaseModel
from bs4 import BeautifulSoup
from dotenv import load_dotenv
from typing import List

load_dotenv()
app = FastAPI(title="KnowledgeLink API")
genai.configure(api_key=os.getenv("GEMINI_API_KEY"))

# CORS middleware is still useful for local development if you ever need it
app.add_middleware(
    CORSMiddleware,
    allow_origins=["http://localhost:3000", os.getenv("NEXTAUTH_URL", "http://localhost:3000")],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

client = motor.motor_asyncio.AsyncIOMotorClient(os.getenv("MONGO_URI"))
db = client.knowledge_link
links_collection = db.links

class LinkSubmission(BaseModel):
    url: str
class LinkData(BaseModel):
    url: str
    title: str
    summary: str

def scrape_text_from_url(url: str):
    try:
        headers = {'User-Agent': 'Mozilla/5.0'}
        response = requests.get(url, headers=headers, timeout=15)
        response.raise_for_status()
        soup = BeautifulSoup(response.content, 'html.parser')
        for script_or_style in soup(["script", "style"]):
            script_or_style.decompose()
        text = soup.get_text()
        lines = (line.strip() for line in text.splitlines())
        chunks = (phrase.strip() for line in lines for phrase in line.split("  "))
        text = "\n".join(chunk for chunk in chunks if chunk)
        title = soup.title.string if soup.title else "No Title Found"
        return title, text
    except requests.RequestException as e:
        print(f"Error scraping {url}: {e}")
        return None, None

async def get_summary_and_embedding(content: str):
    safe_content = content[:8000]
    try:
        embedding_model = "models/text-embedding-004"
        embedding = genai.embed_content(model=embedding_model, content=safe_content, task_type="RETRIEVAL_DOCUMENT")['embedding']
        generation_model = genai.GenerativeModel('gemini-1.5-flash-latest')
        prompt = f"Provide a concise, 3-sentence summary of the following content:\n\n{safe_content[:4000]}"
        summary_response = await generation_model.generate_content_async(prompt)
        return summary_response.text, embedding
    except Exception as e:
        print(f"Error with Gemini API: {e}")
        return None, None

@app.post("/api/links", status_code=201)
async def add_link(link_submission: LinkSubmission):
    user_id = "mock_user_123"
    title, content = scrape_text_from_url(link_submission.url)
    if not content:
        raise HTTPException(status_code=400, detail="Could not scrape content from URL.")
    summary, embedding = await get_summary_and_embedding(content)
    if not summary or not embedding:
        raise HTTPException(status_code=500, detail="AI content generation failed.")
    link_document = {"userId": user_id, "url": link_submission.url, "title": title, "summary": summary, "content_embedding": embedding}
    await links_collection.insert_one(link_document)
    return {"message": "Link added successfully!", "title": title, "summary": summary}

@app.get("/api/links", response_model=List[LinkData])
async def get_links():
    user_id = "mock_user_123"
    links_cursor = links_collection.find({"userId": user_id}).sort("_id", -1)
    links = await links_cursor.to_list(length=100)
    return links

@app.get("/api/search")
async def search_links(q: str):
    if not q:
        raise HTTPException(status_code=400, detail="Query parameter 'q' is required.")
    user_id = "mock_user_123"
    try:
        embedding_model = "models/text-embedding-004"
        query_embedding = genai.embed_content(model=embedding_model, content=q, task_type="RETRIEVAL_QUERY")['embedding']
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Failed to generate query embedding: {e}")
    pipeline = [{"$vectorSearch": {"index": "vector_index", "path": "content_embedding", "queryVector": query_embedding, "numCandidates": 150, "limit": 10}}, {"$match": {"userId": user_id}}, {"$project": {"_id": 0, "url": 1, "title": 1, "summary": 1, "score": {"$meta": "vectorSearchScore"}}}]
    search_results = await links_collection.aggregate(pipeline).to_list(length=10)
    return search_results