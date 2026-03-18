from fastapi import APIRouter, HTTPException
from pydantic import BaseModel
import os
import re

router = APIRouter(prefix='/ai', tags=['ai'])

class QuestionRequest(BaseModel):
    question: str = ""
    context: str = ""
    topic: str = ""

class AnswerResponse(BaseModel):
    answer: str

class AudioResponse(BaseModel):
    audio_url: str

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

def strip_markdown(text: str) -> str:
    text = re.sub(r'\*\*([^*]+)\*\*', r'\1', text)
    text = re.sub(r'\*([^*]+)\*', r'\1', text)
    text = re.sub(r'##\s+', '', text)
    text = re.sub(r'#\s+', '', text)
    text = re.sub(r'```[\s\S]*?```', '', text)
    text = re.sub(r'`([^`]+)`', r'\1', text)
    text = re.sub(r'^\s*[-•]\s+', '', text, flags=re.MULTILINE)
    text = re.sub(r'^\s*\d+\.\s+', '', text, flags=re.MULTILINE)
    text = re.sub(r'\[([^\]]+)\]\([^\)]+\)', r'\1', text)
    text = re.sub(r'\n{3,}', '\n\n', text)
    return text.strip()

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
IMPORTANT: Do NOT use any markdown formatting like **bold**, *italics*, # headers, bullet points, or code blocks.
Use only plain text paragraphs.{topic_info}

Context from simulation: {request.context}
Student's question: {request.question}"""
        
        response = client.chat.completions(
            model="sarvam-m",
            messages=[
                {"role": "system", "content": "You are a friendly science and math tutor for middle and high school students. Always respond in plain text without any markdown formatting."},
                {"role": "user", "content": context}
            ],
            max_tokens=300,
            temperature=0.7
        )
        
        answer = strip_markdown(response.choices[0].message.content)
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
                {"role": "system", "content": """You are a friendly science and math tutor for students in grades 6-12.
IMPORTANT: Always respond in PLAIN TEXT only. Never use:
- No asterisks for bold (*)
- No hash for headers (#)
- No bullet points (- or *)
- No code blocks (```)
- No markdown formatting at all
Just use clear plain paragraphs."""},
                {"role": "user", "content": f"Explain the topic: {topic_info}. Provide a comprehensive but clear explanation suitable for school students. Use only plain text paragraphs."}
            ],
            max_tokens=800,
            temperature=0.7
        )
        
        answer = strip_markdown(response.choices[0].message.content)
        return AnswerResponse(answer=answer)
    except Exception as e:
        raise HTTPException(status_code=500, detail=f'Error getting explanation: {str(e)}')

@router.post('/speak', response_model=AudioResponse)
async def text_to_speech(request: QuestionRequest):
    api_key = os.getenv('SARVAM_API_KEY')
    if not api_key:
        raise HTTPException(status_code=500, detail='SARVAM_API_KEY not configured')
    
    if not request.question:
        raise HTTPException(status_code=400, detail='Text is required for TTS')
    
    try:
        from sarvamai import SarvamAI
        client = SarvamAI(api_subscription_key=api_key)
        
        audio_response = client.text.speech(
            inputs=[request.question],
            model="sarvam-tts",
            target_language="en-IN"
        )
        
        audio_base64 = audio_response.audio[0].audio_base64
        
        return AudioResponse(audio_url=f"data:audio/wav;base64,{audio_base64}")
    except Exception as e:
        raise HTTPException(status_code=500, detail=f'Error generating audio: {str(e)}')
