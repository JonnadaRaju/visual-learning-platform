from fastapi import APIRouter, HTTPException
from pydantic import BaseModel
import os
import httpx

router = APIRouter(prefix='/ai', tags=['ai'])

class QuestionRequest(BaseModel):
    question: str
    context: str = ""

class AnswerResponse(BaseModel):
    answer: str

@router.post('/ask', response_model=AnswerResponse)
async def ask_question(request: QuestionRequest):
    api_key = os.getenv('OPENROUTER_KEY')
    if not api_key:
        raise HTTPException(status_code=500, detail='AI API key not configured')
    
    context = f"""You are a helpful physics and science tutor for school students (grades 6-12).
Help students understand concepts simply and clearly. Keep answers short and friendly.
If the question is about a simulation they were using, use that context.

Context: {request.context}
Student's question: {request.question}"""

    try:
        async with httpx.AsyncClient() as client:
            response = await client.post(
                "https://openrouter.ai/api/v1/chat/completions",
                headers={
                    "Authorization": f"Bearer {api_key}",
                    "HTTP-Referer": "https://eduviz-a3234.web.app",
                    "X-Title": "EduViz",
                },
                json={
                    "model": "google/gemma-3n-e4b",
                    "messages": [
                        {"role": "system", "content": "You are a friendly science tutor for middle and high school students."},
                        {"role": "user", "content": context}
                    ],
                    "max_tokens": 300,
                    "temperature": 0.7
                },
                timeout=30.0
            )
            
            if response.status_code != 200:
                raise Exception(f"API error: {response.text}")
            
            data = response.json()
            answer = data['choices'][0]['message']['content']
            return AnswerResponse(answer=answer)
    except Exception as e:
        raise HTTPException(status_code=500, detail=f'Error getting answer: {str(e)}')
