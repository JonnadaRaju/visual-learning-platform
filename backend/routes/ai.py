from fastapi import APIRouter, HTTPException
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
    language: str = "en-IN"  # 'en-IN' or 'te-IN'


class TTSResponse(BaseModel):
    audio_base64: str
    content_type: str = "audio/wav"


# Sarvam bulbul:v3 — max 500 chars per input
SARVAM_MAX_CHARS = 500

# Confirmed bulbul:v3 speakers from Sarvam dashboard
TELUGU_SPEAKER  = "neha"  # female voice for te-IN
ENGLISH_SPEAKER = "ritu"  # female voice for en-IN

TOPIC_CONTEXT = {
    "projectile-motion":  "Projectile Motion - Learn about motion in two dimensions, equations for trajectory, time of flight, maximum height, and horizontal range.",
    "waves-shm":          "Waves and Simple Harmonic Motion - Understand wave properties, frequency, amplitude, wavelength, and simple harmonic motion.",
    "electric-circuits":  "Electric Circuits - Study Ohm's law, series and parallel circuits, voltage, current, and resistance.",
    "gravitation-orbits": "Gravitation and Orbits - Learn about Newton's law of gravitation, orbital motion, and satellite concepts.",
    "newtons-laws":       "Newton's Laws of Motion - Understand the three laws of motion and their applications.",
    "fluid-pressure":     "Fluid Pressure - Learn about pressure in fluids, Pascal's principle, and buoyancy.",
    "linear-equations":   "Linear Equations - Solve and graph linear equations in two variables.",
    "geometry":           "Geometry - Learn about shapes, areas, volumes, and geometric theorems.",
    "atomic-structure":   "Atomic Structure - Understand the structure of atoms, electrons, protons, neutrons, and electron configuration.",
    "acids-bases":        "Acids and Bases - Learn about properties of acids and bases, pH scale, and neutralization reactions.",
}


def strip_markdown(text: str) -> str:
    """Remove <think> tags and markdown formatting."""
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


async def _translate_to_telugu(text: str, api_key: str) -> str:
    """
    Translate English text to Telugu using Sarvam Translate API.
    Splits into chunks of 1000 chars (Sarvam translate limit).
    """
    # Sarvam translate supports up to ~1000 chars per request
    TRANSLATE_MAX = 900
    chunks = _split_text(text, TRANSLATE_MAX)
    translated_chunks = []

    async with httpx.AsyncClient(timeout=30) as client:
        for chunk in chunks:
            payload = {
                "input": chunk,
                "source_language_code": "en-IN",
                "target_language_code": "te-IN",
                "speaker_gender": "Female",
                "mode": "formal",
                "model": "mayura:v1",
                "enable_preprocessing": False,
            }
            response = await client.post(
                "https://api.sarvam.ai/translate",
                json=payload,
                headers={
                    "api-subscription-key": api_key,
                    "Content-Type": "application/json",
                },
            )
            if response.status_code != 200:
                # If translation fails, fall back to original English chunk
                translated_chunks.append(chunk)
            else:
                data = response.json()
                translated = data.get("translated_text", chunk)
                translated_chunks.append(translated)

    return " ".join(translated_chunks)


def _split_text(text: str, max_chars: int = SARVAM_MAX_CHARS) -> list:
    """
    Split text into chunks of max_chars at sentence boundaries.
    """
    chunks = []
    sentences = re.split(r'(?<=[.!?])\s+', text.strip())
    current = ""

    for sentence in sentences:
        # If a single sentence is too long, hard-split by words
        if len(sentence) > max_chars:
            if current:
                chunks.append(current.strip())
                current = ""
            words = sentence.split()
            temp = ""
            for word in words:
                if len(temp) + len(word) + 1 <= max_chars:
                    temp = f"{temp} {word}".strip()
                else:
                    if temp:
                        chunks.append(temp.strip())
                    temp = word
            if temp:
                chunks.append(temp.strip())
        elif len(current) + len(sentence) + 1 <= max_chars:
            current = f"{current} {sentence}".strip()
        else:
            if current:
                chunks.append(current.strip())
            current = sentence

    if current:
        chunks.append(current.strip())

    return [c for c in chunks if c]


async def _tts_chunk(
    client: httpx.AsyncClient,
    text: str,
    language: str,
    speaker: str,
    api_key: str,
) -> str:
    """Call Sarvam TTS for a single chunk, return base64 WAV string."""
    payload = {
        "inputs": [text],
        "target_language_code": language,
        "speaker": speaker,
        "model": "bulbul:v3",
        "speech_sample_rate": 22050,
        "enable_preprocessing": True,
        "pace": 1.0,
    }
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
    audios = data.get("audios", [])
    if not audios:
        raise HTTPException(status_code=502, detail='No audio returned from Sarvam TTS')
    return audios[0]


def _combine_wav_base64(b64_list: list) -> str:
    """
    Combine multiple WAV base64 strings into one WAV file
    by merging PCM data and fixing WAV header.
    """
    import struct

    if len(b64_list) == 1:
        return b64_list[0]

    combined_pcm = b""
    header = None

    for i, b64 in enumerate(b64_list):
        wav_bytes = base64.b64decode(b64)
        if i == 0:
            header = wav_bytes[:44]
            combined_pcm += wav_bytes[44:]
        else:
            combined_pcm += wav_bytes[44:]

    if header is None:
        return b64_list[0]

    data_size = len(combined_pcm)
    file_size = 36 + data_size
    new_header = bytearray(header)
    struct.pack_into('<I', new_header, 4, file_size)
    struct.pack_into('<I', new_header, 40, data_size)

    combined_wav = bytes(new_header) + combined_pcm
    return base64.b64encode(combined_wav).decode('utf-8')


# ── TTS endpoint ──────────────────────────────────────────────────────────────
@router.post('/tts', response_model=TTSResponse)
async def text_to_speech(request: TTSRequest):
    api_key = os.getenv('SARVAM_API_KEY')
    if not api_key:
        raise HTTPException(status_code=500, detail='SARVAM_API_KEY not configured')

    speaker = TELUGU_SPEAKER if request.language == 'te-IN' else ENGLISH_SPEAKER

    # Clean text first
    clean_text = strip_markdown(request.text)

    # If Telugu requested — translate English → Telugu first
    if request.language == 'te-IN':
        clean_text = await _translate_to_telugu(clean_text, api_key)

    # Split into <=500 char chunks for TTS
    chunks = _split_text(clean_text, SARVAM_MAX_CHARS)
    if not chunks:
        raise HTTPException(status_code=400, detail='No text to convert')

    try:
        async with httpx.AsyncClient(timeout=60) as client:
            b64_list = []
            for chunk in chunks:
                b64 = await _tts_chunk(
                    client, chunk, request.language, speaker, api_key
                )
                b64_list.append(b64)

        combined = _combine_wav_base64(b64_list)
        return TTSResponse(audio_base64=combined, content_type="audio/wav")

    except httpx.TimeoutException:
        raise HTTPException(status_code=504, detail='Sarvam TTS request timed out')
    except HTTPException:
        raise
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

IMPORTANT: Plain text only. No markdown, no asterisks, no headers, no bullet points. Never include <think> tags.{topic_info}

Context: {request.context}
Question: {request.question}"""

        response = client.chat.completions(
            model="sarvam-m",
            messages=[
                {"role": "system", "content": "You are a friendly science tutor. Plain text only. No markdown. No <think> tags."},
                {"role": "user", "content": context},
            ],
            max_tokens=400,
            temperature=0.7,
        )

        answer = strip_markdown(response.choices[0].message.content)
        return AnswerResponse(answer=answer)

    except HTTPException:
        raise
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
                {"role": "user", "content": f"Explain for school students: {topic_info}. Use real-life Indian examples. Plain text paragraphs only."},
            ],
            max_tokens=800,
            temperature=0.7,
        )

        answer = strip_markdown(response.choices[0].message.content)
        return AnswerResponse(answer=answer)

    except HTTPException:
        raise
    except Exception as e:
        raise HTTPException(status_code=500, detail=f'Error: {str(e)}')