from fastapi import APIRouter, HTTPException
from fastapi.responses import Response
from pydantic import BaseModel
import os
import re
import base64
import httpx

router = APIRouter(prefix='/ai', tags=['ai'])


class QuestionRequest(BaseModel):
    question: str = ""
    context: str = ""
    topic: str = ""


class AnswerResponse(BaseModel):
    answer: str


class TTSRequest(BaseModel):
    text: str
    language: str = "en-IN"   # 'en-IN' or 'te-IN'
    speaker: str = "meera"    # default speaker


class TTSResponse(BaseModel):
    audio_base64: str          # base64 encoded WAV
    content_type: str = "audio/wav"


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

# Telugu speaker voices available in Sarvam bulbul:v3
TELUGU_SPEAKER = "pavithra"   # female Telugu voice
ENGLISH_SPEAKER = "meera"     # female English-IN voice


def strip_markdown(text: str) -> str:
    # Remove <think>...</think> blocks
    text = re.sub(r'<think>[\s\S]*?</think>', '', text, flags=re.IGNORECASE)
    text = re.sub(r'</?think>', '', text, flags=re.IGNORECASE)
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


# ── TTS endpoint ──────────────────────────────────────────────────────────────
@router.post('/tts', response_model=TTSResponse)
async def text_to_speech(request: TTSRequest):
    api_key = os.getenv('SARVAM_API_KEY')
    if not api_key:
        raise HTTPException(status_code=500, detail='SARVAM_API_KEY not configured')

    # Pick correct speaker based on language
    speaker = TELUGU_SPEAKER if request.language == 'te-IN' else ENGLISH_SPEAKER

    # Sarvam bulbul:v3 max 2500 chars — truncate if needed
    text = request.text[:2500]

    payload = {
        "inputs": [text],
        "target_language_code": request.language,
        "speaker": speaker,
        "model": "bulbul:v3",
        "speech_sample_rate": 22050,
        "enable_preprocessing": True,
        "pace": 1.0,
    }

    try:
        async with httpx.AsyncClient(timeout=30) as client:
            response = await client.post(
                "https://api.sarvam.ai/text-to-speech",
                json=payload,
                headers={
                    "api-subscription-key": api_key,
                    "Content-Type": "application/json",
                },
            )

        if response.status_code != 200:
            raise HTTPException(
                status_code=502,
                detail=f'Sarvam TTS error {response.status_code}: {response.text}',
            )

        data = response.json()
        # Sarvam returns list of base64 strings in "audios"
        audios = data.get("audios", [])
        if not audios:
            raise HTTPException(status_code=502, detail='No audio returned from Sarvam TTS')

        return TTSResponse(audio_base64=audios[0], content_type="audio/wav")

    except httpx.TimeoutException:
        raise HTTPException(status_code=504, detail='Sarvam TTS request timed out')
    except Exception as e:
        raise HTTPException(status_code=500, detail=f'TTS error: {str(e)}')


# ── Ask endpoint ──────────────────────────────────────────────────────────────
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
Explain concepts in simple, easy-to-understand language. Use real-life Indian examples (cricket, cooking, vehicles, etc.).
Structure your response in 4 plain text paragraphs:
1. Simple one-sentence definition
2. Real-life everyday Indian example
3. Key concept explained simply
4. One interesting fact

IMPORTANT: Plain text only. No markdown, no asterisks, no headers, no bullet points.
Never include <think> tags.{topic_info}

Context: {request.context}
Question: {request.question}"""

        response = client.chat.completions(
            model="sarvam-m",
            messages=[
                {"role": "system", "content": "You are a friendly science tutor. Plain text only. No markdown. No <think> tags."},
                {"role": "user", "content": context}
            ],
            max_tokens=400,
            temperature=0.7
        )

        answer = strip_markdown(response.choices[0].message.content)
        return AnswerResponse(answer=answer)
    except Exception as e:
        raise HTTPException(status_code=500, detail=f'Error: {str(e)}')


# ── Explain endpoint ──────────────────────────────────────────────────────────
@router.post('/explain', response_model=AnswerResponse)
async def explain_topic(request: QuestionRequest):
    topic = request.topic
    api_key = os.getenv('SARVAM_API_KEY')
    if not api_key:
        raise HTTPException(status_code=500, detail='SARVAM_API_KEY not configured')

    topic_info = TOPIC_CONTEXT.get(topic, f"Explain the topic: {topic}")

    try:
        from sarvamai import SarvamAI
        client = SarvamAI(api_subscription_key=api_key)

        response = client.chat.completions(
            model="sarvam-m",
            messages=[
                {"role": "system", "content": """You are a friendly science and math tutor for students in grades 6-12.
Always respond in PLAIN TEXT only. No asterisks, no headers, no bullet points, no markdown, no <think> tags.
Structure your explanation in exactly 4 paragraphs:
Paragraph 1: Simple definition with a real-life Indian example (cricket ball, cooking, fan, auto-rickshaw, etc.)
Paragraph 2: Key concepts explained simply
Paragraph 3: How it works step by step in plain language
Paragraph 4: One interesting real-world application"""},
                {"role": "user", "content": f"Explain for school students: {topic_info}. Use real-life Indian examples. Plain text paragraphs only."}
            ],
            max_tokens=800,
            temperature=0.7
        )

        answer = strip_markdown(response.choices[0].message.content)
        return AnswerResponse(answer=answer)
    except Exception as e:
        raise HTTPException(status_code=500, detail=f'Error: {str(e)}')