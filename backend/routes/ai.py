from fastapi import APIRouter, HTTPException
from pydantic import BaseModel
import os

router = APIRouter(prefix='/ai', tags=['ai'])

class QuestionRequest(BaseModel):
    question: str
    context: str = ""

class AnswerResponse(BaseModel):
    answer: str

@router.post('/ask', response_model=AnswerResponse)
async def ask_question(request: QuestionRequest):
    from openai import OpenAI
    
    api_key = os.getenv('OPENAI_API_KEY')
    if not api_key:
        raise HTTPException(status_code=500, detail='OpenAI API key not configured')
    
    client = OpenAI(api_key=api_key)
    
    context = f"""You are a helpful physics and science tutor for school students (grades 6-12).
Help students understand concepts simply and clearly. If the question is about a simulation 
they were using, use that context. Keep answers short and friendly.

Context: {request.context}
Student's question: {request.question}"""

    try:
        response = client.chat.completions.create(
            model="gpt-3.5-turbo",
            messages=[
                {"role": "system", "content": "You are a friendly science tutor for middle and high school students."},
                {"role": "user", "content": context}
            ],
            max_tokens=300,
            temperature=0.7
        )
        
        answer = response.choices[0].message.content
        return AnswerResponse(answer=answer)
    except Exception as e:
        raise HTTPException(status_code=500, detail=f'Error getting answer: {str(e)}')
