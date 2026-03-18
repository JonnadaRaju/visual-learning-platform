from fastapi import APIRouter, HTTPException
from pydantic import BaseModel
import os

router = APIRouter(prefix='/ai', tags=['ai'])

class QuestionRequest(BaseModel):
    question: str = ""
    context: str = ""
    topic: str = ""

class AnswerResponse(BaseModel):
    answer: str

TOPIC_CONTEXT = {
    "projectile-motion": "Projectile Motion - Learn about motion in two dimensions, equations for trajectory, time of flight, maximum height, and horizontal range.",
    "waves-shm": "Waves and Simple Harmonic Motion - Understand wave properties, frequency, amplitude, wavelength, and simple harmonic motion.",
    "electric-circuits": "Electric Circuits - Study Ohm's law, series and parallel circuits, voltage, current, and resistance.",
    "gravitation-orbits": "Gravitation and Orbits - Learn about Newton's law of gravitation, orbital motion, and satellite concepts.",
    "newtons-laws": "Newton's Laws of Motion - Understand the three laws of motion and their applications.",
    "fluid-pressure": "Fluid Pressure - Learn about pressure in fluids, Pascal's principle, and buoyancy.",
    "linear-equations": "Linear Equations - Solve and graph linear equations in two variables.",
    "geometry": "Geometry - Learn about shapes, areas, volumes, and geometric theorems.",
    "atomic-structure": "Atomic Structure - Understand the structure of atoms, electrons, protons, neutrons, and electron configuration.",
    "acids-bases": "Acids and Bases - Learn about properties of acids and bases, pH scale, and neutralization reactions.",
}

@router.post('/ask', response_model=AnswerResponse)
async def ask_question(request: QuestionRequest):
    api_key = os.getenv('SARVAM_API_KEY')
    if not api_key:
        raise HTTPException(status_code=500, detail='SARVAM_API_KEY not configured')
    
    try:
        from sarvamai import SarvamAI
        client = SarvamAI(api_subscription_key=api_key)
        
        topic_info = TOPIC_CONTEXT.get(request.topic, "")
        if topic_info:
            topic_info = f"\n\nCurrent Topic: {topic_info}"
        
        context = f"""You are a friendly and helpful science and math tutor for school students (grades 6-12).
Explain concepts in simple, easy-to-understand language. Use examples from everyday life when possible.
Keep answers concise and friendly.{topic_info}

Context from simulation: {request.context}
Student's question: {request.question}"""
        
        response = client.chat.completions(
            model="sarvam-m",
            messages=[
                {"role": "system", "content": "You are a friendly science and math tutor for middle and high school students."},
                {"role": "user", "content": context}
            ],
            max_tokens=300,
            temperature=0.7
        )
        
        answer = response.choices[0].message.content
        return AnswerResponse(answer=answer)
    except Exception as e:
        raise HTTPException(status_code=500, detail=f'Error getting answer: {str(e)}')

@router.post('/explain', response_model=AnswerResponse)
async def explain_topic(request: QuestionRequest):
    topic = request.topic
    api_key = os.getenv('SARVAM_API_KEY')
    if not api_key:
        raise HTTPException(status_code=500, detail='SARVAM_API_KEY not configured')
    
    topic_info = TOPIC_CONTEXT.get(topic, "")
    if not topic_info:
        topic_info = f"Explain the topic: {topic}"
    
    try:
        from sarvamai import SarvamAI
        client = SarvamAI(api_subscription_key=api_key)
        
        response = client.chat.completions(
            model="sarvam-m",
            messages=[
                {"role": "system", "content": "You are a friendly science and math tutor for middle and high school students. Explain concepts in simple, easy-to-understand language."},
                {"role": "user", "content": f"Give a brief explanation of {topic_info}. Include what it is, why it's important, and a simple example."}
            ],
            max_tokens=500,
            temperature=0.7
        )
        
        answer = response.choices[0].message.content
        return AnswerResponse(answer=answer)
    except Exception as e:
        raise HTTPException(status_code=500, detail=f'Error getting explanation: {str(e)}')
