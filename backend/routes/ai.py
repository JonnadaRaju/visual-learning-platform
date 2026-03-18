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
    # Remove <think>...</think> blocks (reasoning tokens leaking out)
    text = re.sub(r'<think>[\s\S]*?</think>', '', text, flags=re.IGNORECASE)
    # Remove any leftover <think> or </think> tags
    text = re.sub(r'</?think>', '', text, flags=re.IGNORECASE)
    # Remove bold/italic markdown
    text = re.sub(r'\*\*([^*]+)\*\*', r'\1', text)
    text = re.sub(r'\*([^*]+)\*', r'\1', text)
    # Remove headers
    text = re.sub(r'##\s+', '', text)
    text = re.sub(r'#\s+', '', text)
    # Remove code blocks
    text = re.sub(r'```[\s\S]*?```', '', text)
    text = re.sub(r'`([^`]+)`', r'\1', text)
    # Remove bullet points
    text = re.sub(r'^\s*[-•]\s+', '', text, flags=re.MULTILINE)
    text = re.sub(r'^\s*\d+\.\s+', '', text, flags=re.MULTILINE)
    # Remove links
    text = re.sub(r'\[([^\]]+)\]\([^\)]+\)', r'\1', text)
    # Collapse excess newlines
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
Explain concepts in simple, easy-to-understand language. Use real-life examples from everyday life.
Structure your response in clear paragraphs like:
- Start with a simple one-sentence definition
- Give a real-life everyday example
- Explain the key concept in 2-3 sentences
- End with one interesting fact

IMPORTANT: Do NOT use any markdown. No asterisks, no headers, no bullet points. Plain text paragraphs only.{topic_info}

Context from simulation: {request.context}
Student's question: {request.question}"""

        response = client.chat.completions(
            model="sarvam-m",
            messages=[
                {"role": "system", "content": "You are a friendly science and math tutor for school students. Always respond in plain text without any markdown formatting. Never include <think> tags or reasoning in your response."},
                {"role": "user", "content": context}
            ],
            max_tokens=400,
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
Always respond in PLAIN TEXT only. Never use asterisks, hash headers, bullet points, or any markdown.
Structure your explanation clearly in paragraphs:
Paragraph 1: Simple definition with a real-life everyday example (like cricket ball, cooking, fan, etc.)
Paragraph 2: Key concepts explained simply
Paragraph 3: How it works step by step in plain language
Paragraph 4: One interesting real-world application students can relate to
Never include <think> tags or internal reasoning in your response."""},
                {"role": "user", "content": f"Explain this topic for school students: {topic_info}. Use real-life Indian examples like cricket, cooking, vehicles, etc. Plain text paragraphs only."}
            ],
            max_tokens=800,
            temperature=0.7
        )

        answer = strip_markdown(response.choices[0].message.content)
        return AnswerResponse(answer=answer)
    except Exception as e:
        raise HTTPException(status_code=500, detail=f'Error getting explanation: {str(e)}')