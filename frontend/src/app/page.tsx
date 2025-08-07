// src/app/page.tsx

"use client";

import { useState, useEffect } from "react";
import { useSession, signIn, signOut } from "next-auth/react";
import axios from "axios";
import { LogIn, Plus, Search, Link as LinkIcon, Loader2, LogOut } from "lucide-react";

interface Link {
  url: string;
  title: string;
  summary: string;
  score?: number;
}

const API_BASE_URL = ""; 

export default function Home() {
  const { data: session, status } = useSession();
  const [url, setUrl] = useState("");
  const [links, setLinks] = useState<Link[]>([]);
  const [searchQuery, setSearchQuery] = useState("");
  const [searchResults, setSearchResults] = useState<Link[]>([]);
  const [isLoading, setIsLoading] = useState(false);
  const [isSearching, setIsSearching] = useState(false);
  
  const fetchLinks = async () => {
    if (!session) return;
    try {
      const response = await axios.get(`${API_BASE_URL}/api/links`);
      setLinks(response.data);
    } catch (error) { console.error("Failed to fetch links:", error); }
  };
  
  useEffect(() => { fetchLinks(); }, [session]);

  const handleAddLink = async (e: React.FormEvent) => {
    e.preventDefault();
    if (!url) return;
    setIsLoading(true);
    try {
      await axios.post(`${API_BASE_URL}/api/links`, { url });
      setUrl("");
      await fetchLinks();
    } catch (error) {
      console.error("Failed to add link:", error);
      alert("Failed to add link. Is the URL valid and public?");
    } finally { setIsLoading(false); }
  };

  const handleSearch = async (e: React.FormEvent) => {
    e.preventDefault();
    if (!searchQuery) {
        setSearchResults([]);
        return;
    };
    setIsSearching(true);
    try {
        const response = await axios.get(`${API_BASE_URL}/api/search?q=${encodeURIComponent(searchQuery)}`);
        setSearchResults(response.data);
    } catch (error) {
        console.error("Search failed:", error);
    } finally { setIsSearching(false); }
  }

  if (status === "loading") {
    return <div className="flex items-center justify-center min-h-screen"><Loader2 className="h-10 w-10 animate-spin text-gray-500"/></div>;
  }

  if (!session) {
    return (
      <main className="flex min-h-screen flex-col items-center justify-center bg-gray-50 text-center p-4">
        <h1 className="text-5xl font-bold mb-4">Welcome to KnowledgeLink</h1>
        <p className="text-lg text-gray-600 mb-8 max-w-xl">Your personal, searchable knowledge base. Save links, get AI summaries, and find what you need with natural language.</p>
        <button onClick={() => signIn("google")} className="bg-blue-600 hover:bg-blue-700 text-white font-bold py-3 px-6 rounded-lg flex items-center shadow-lg transition-transform transform hover:scale-105"><LogIn className="mr-2 h-5 w-5" /> Sign in with Google</button>
      </main>
    );
  }

  return (
    <main className="min-h-screen bg-gray-100 p-4 sm:p-8 font-sans">
      <div className="max-w-4xl mx-auto bg-white rounded-xl shadow-md p-6">
        <header className="flex justify-between items-center mb-6 pb-4 border-b">
            <div>
                <h1 className="text-3xl font-bold text-gray-800">KnowledgeLink</h1>
                <p className="text-sm text-gray-500">Welcome, {session.user?.name}</p>
            </div>
            <button onClick={() => signOut()} className="bg-gray-200 hover:bg-red-100 text-gray-700 hover:text-red-700 font-semibold py-2 px-4 rounded-lg flex items-center transition-colors"><LogOut className="mr-2 h-4 w-4"/> Sign Out</button>
        </header>

        <section className="mb-6">
          <form onSubmit={handleAddLink} className="flex flex-col sm:flex-row gap-2">
            <input type="url" value={url} onChange={(e) => setUrl(e.target.value)} placeholder="Paste a URL to save and summarize..." className="flex-grow p-3 border-2 border-gray-200 rounded-lg focus:ring-2 focus:ring-blue-500 focus:border-blue-500 transition" required />
            <button type="submit" disabled={isLoading} className="bg-blue-600 text-white p-3 rounded-lg flex items-center justify-center w-full sm:w-32 hover:bg-blue-700 disabled:bg-blue-300 transition-colors">{isLoading ? <Loader2 className="animate-spin h-5 w-5"/> : <><Plus className="mr-1 h-5 w-5"/> Add Link</>}</button>
          </form>
        </section>

        <section>
          <form onSubmit={handleSearch} className="flex flex-col sm:flex-row gap-2 mb-6">
              <input type="text" value={searchQuery} onChange={(e) => setSearchQuery(e.target.value)} placeholder="Ask a question about your links..." className="flex-grow p-3 border-2 border-gray-200 rounded-lg focus:ring-2 focus:ring-green-500 focus:border-green-500 transition" />
              <button type="submit" disabled={isSearching} className="bg-green-600 text-white p-3 rounded-lg flex items-center justify-center w-full sm:w-32 hover:bg-green-700 disabled:bg-green-300 transition-colors">{isSearching ? <Loader2 className="animate-spin h-5 w-5"/> : <><Search className="mr-1 h-5 w-5"/> Search</>}</button>
          </form>
        </section>

        <div className="space-y-4">
          <h2 className="text-2xl font-semibold text-gray-700 border-b pb-2">{searchResults.length > 0 || searchQuery ? "Search Results" : "My Saved Links"}</h2>
          
          {(searchResults.length > 0 ? searchResults : links).map((link, index) => {
            // DEBUGGING: Log each link object to the console
            console.log("Rendering link:", link);

            return (
              <div key={index} className="bg-gray-50 p-4 rounded-lg border border-gray-200 hover:shadow-sm transition-shadow">
                  <div className="flex items-center mb-2">
                      <img src={`https://www.google.com/s2/favicons?domain=${link.url}&sz=16`} alt="favicon" className="mr-2"/>
                      <a href={link.url} target="_blank" rel="noopener noreferrer" className="text-blue-600 hover:underline font-semibold truncate text-lg">{link.title}</a>
                  </div>
                  <p className="text-gray-600 text-sm leading-relaxed">{link.summary}</p>
                  {link.score && <p className="text-xs text-green-700 mt-2 font-mono">Relevance Score: {link.score.toFixed(4)}</p>}
              </div>
            );
          })}
          
          {links.length === 0 && searchResults.length === 0 && !searchQuery && (
            <div className="text-center py-10 px-4 bg-gray-50 rounded-lg">
                <p className="text-gray-500">You haven&apos;t saved any links yet.</p>
                <p className="text-gray-400 text-sm">Paste a URL above to get started!</p>
            </div>
          )}
        </div>
      </div>
    </main>
  );
}