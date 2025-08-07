import type { NextConfig } from 'next'

const nextConfig: NextConfig = {
  // This rewrites rule is crucial for production deployment
  async rewrites() {
    return [
      {
        source: '/api/:path*',
        // This needs to match the port your FastAPI server runs on
        destination: 'http://127.0.0.1:8000/api/:path*', 
      },
    ]
  },
}

export default nextConfig