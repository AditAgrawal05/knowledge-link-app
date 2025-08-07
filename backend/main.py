# backend/main.py

import os
import requests
import motor.motor_asyncio
import google.generativeai as genai
from fastapi import FastAPI, HTTPException, Request
from fastapi.middleware.cors import CORSMiddleware
from pydantic import BaseModel
from bs4 import BeautifulSoup
from dotenv import load_dotenv
from typing import List
# from fastapi.staticfiles import StaticFiles

# Load environment variables from .env file
load_dotenv()

# --- App & Service Configuration ---
app = FastAPI(title="KnowledgeLink API")

# This line tells FastAPI to serve the static Next.js files
# app.mount("/", StaticFiles(directory="/app/static", html=True), name="static")

# Configure Google Gemini API
genai.configure(api_key=os.getenv("GEMINI_API_KEY"))

# Configure CORS (Cross-Origin Resource Sharing)
# This allows our Next.js frontend to communicate with this backend.
app.add_middleware(
    CORSMiddleware,
    allow_origins=["http://localhost:3000"], # IMPORTANT: Add your deployed frontend URL here later
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# --- MongoDB Connection ---
client = motor.motor_asyncio.AsyncIOMotorClient(os.getenv("MONGO_URI"))
db = client.knowledge_link
links_collection = db.links

# --- Pydantic Models (Data Schemas) ---
class LinkSubmission(BaseModel):
    url: str

class LinkData(BaseModel):
    url: str
    title: str
    summary: str

# --- Helper Functions ---
# backend/main.py

def scrape_text_from_url(url: str):
    """Scrapes the primary text content and title from a URL."""
    try:
        # Add a User-Agent header to mimic a browser and increase timeout
        headers = {'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/58.0.3029.110 Safari/537.3'}
        response = requests.get(url, headers=headers, timeout=15)
        response.raise_for_status() # Raise an exception for bad status codes (4xx or 5xx)

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
        print(f"Error scraping {url}: {e}") # This will print the error in your backend terminal
        return None, None

# backend/main.py

# backend/main.py

async def get_summary_and_embedding(content: str):
    """Generates a summary and a vector embedding using the Gemini API."""
    safe_content = content[:8000] 

    try:
        embedding_model = "models/text-embedding-004"
        embedding = genai.embed_content(
            model=embedding_model,
            content=safe_content,
            task_type="RETRIEVAL_DOCUMENT"
        )['embedding']

        # Use a more current and specific model name
        generation_model = genai.GenerativeModel('gemini-1.5-flash-latest')

        prompt = f"Provide a concise, 3-sentence summary of the following content:\n\n{safe_content[:4000]}"
        summary_response = await generation_model.generate_content_async(prompt)

        return summary_response.text, embedding
    except Exception as e:
        print(f"Error with Gemini API: {e}")
        return None, None

# --- API Endpoints ---
@app.get("/")
def read_root():
    return {"status": "KnowledgeLink API is running!"}

@app.post("/api/links", status_code=201)
async def add_link(link_submission: LinkSubmission):
    # In a real app, you'd get userId from the authenticated session
    user_id = "mock_user_123" 

    title, content = scrape_text_from_url(link_submission.url)
    if not content:
        raise HTTPException(status_code=400, detail="Could not scrape content from URL.")

    summary, embedding = await get_summary_and_embedding(content)
    if not summary or not embedding:
        raise HTTPException(status_code=500, detail="AI content generation failed.")

    link_document = {
        "userId": user_id,
        "url": link_submission.url,
        "title": title,
        "summary": summary,
        "content_embedding": embedding,
    }
    
    await links_collection.insert_one(link_document)
    return {"message": "Link added successfully!", "title": title, "summary": summary}

@app.get("/api/links", response_model=List[LinkData])
async def get_links():
    user_id = "mock_user_123"
    links_cursor = links_collection.find({"userId": user_id}).sort("_id", -1) # Sort by most recent
    links = await links_cursor.to_list(length=100)
    return links

@app.get("/api/search")
async def search_links(q: str):
    if not q:
        raise HTTPException(status_code=400, detail="Query parameter 'q' is required.")

    user_id = "mock_user_123"
    
    try:
        embedding_model = "models/text-embedding-004"
        query_embedding = genai.embed_content(
            model=embedding_model,
            content=q,
            task_type="RETRIEVAL_QUERY" # Use RETRIEVAL_QUERY for search queries
        )['embedding']
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Failed to generate query embedding: {e}")

    pipeline = [
        {
            "$vectorSearch": {
                "index": "vector_index", # The name of your Atlas Vector Search index
                "path": "content_embedding",
                "queryVector": query_embedding,
                "numCandidates": 150,
                "limit": 10,
            }
        },
        { "$match": { "userId": user_id } },
        {
            "$project": {
                "_id": 0,
                "url": 1,
                "title": 1,
                "summary": 1,
                "score": { "$meta": "vectorSearchScore" }
            }
        }
    ]
    
    search_results = await links_collection.aggregate(pipeline).to_list(length=10)
    return search_results