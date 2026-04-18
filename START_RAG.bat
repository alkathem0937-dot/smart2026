@echo off
echo Starting Local RAG Engine...
cd rag_engine
uvicorn main:app --host 0.0.0.0 --port 8080
pause
