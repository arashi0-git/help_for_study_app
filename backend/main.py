from fastapi import FastAPI, HTTPException
from fastapi.middleware.cors import CORSMiddleware
from pydantic import BaseModel
from langchain_openai import ChatOpenAI
from langchain.prompts import ChatPromptTemplate
from langchain.chains import LLMChain
from langchain_community.embeddings import OpenAIEmbeddings
from langchain_community.vectorstores import FAISS
from langchain.text_splitter import CharacterTextSplitter
import os
from dotenv import load_dotenv
import sys
from pathlib import Path
import traceback
import numpy as np

# プロジェクトのルートディレクトリを取得
ROOT_DIR = Path(__file__).resolve().parent.parent
sys.path.append(str(ROOT_DIR))

# 環境変数の読み込み
load_dotenv(ROOT_DIR / '.env')

# APIキーの確認
api_key = os.getenv("OPENAI_API_KEY")
if not api_key:
    raise ValueError("OPENAI_API_KEYが設定されていません。.envファイルを確認してください。")

app = FastAPI()

# CORSの設定
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],  # 本番環境では適切に制限してください
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# モデルの初期化
llm = ChatOpenAI(
    model_name="gpt-4",
    temperature=0.7,
    openai_api_key=api_key
)

embeddings = OpenAIEmbeddings(
    openai_api_key=api_key
)

# プロンプトテンプレート
PROMPT_TEMPLATE = """
あなたは数学の教師です。以下の問題における解答を採点し、詳細なフィードバックを提供してください。

問題: {problem}
解答: {answer}

{reference_answer}

上記リファレンスはあくまで参考資料です。与えられた問題と解答は一致するとは限りません。

この解答を採点し、以下の点について評価してください：
1. 正解かどうか
2. 計算過程の正確さ
もし、不正解ならば、以下の点について詳細に指摘してください：
3. 改善点やアドバイス
4. 詳細な解説

回答は日本語で、親しみやすい口調でお願いします。
"""

prompt = ChatPromptTemplate.from_template(PROMPT_TEMPLATE)
chain = LLMChain(llm=llm, prompt=prompt)

# サンプル解答の読み込みとベクトルストアの初期化
def load_sample_answers():
    try:
        with open(ROOT_DIR / "assets/sample_answers.txt", "r", encoding="utf-8") as f:
            text = f.read()
        
        text_splitter = CharacterTextSplitter(
            separator="\n\n",
            chunk_size=1000,
            chunk_overlap=200
        )
        texts = text_splitter.split_text(text)
        
        return FAISS.from_texts(texts, embeddings)
    except Exception as e:
        print(f"サンプル解答の読み込みエラー: {e}")
        return FAISS.from_texts([], embeddings)  # 空のベクトルストアを返す

vectorstore = load_sample_answers()

class ScoringRequest(BaseModel):
    problem: str
    answer: str

@app.post("/score")
async def score_answer(request: ScoringRequest):
    try:
        # 類似の問題と解答を検索
        docs = vectorstore.similarity_search(request.problem, k=1)
        reference_answer = ""
        if docs:
            # それぞれのテキストをベクトル化
            vec1 = embeddings.embed_query(request.problem)
            vec2 = embeddings.embed_query(docs[0].page_content)
            similarity = cosine_similarity(vec1, vec2)
            if similarity > 0.75:
                reference_answer = f"参考解答例:\n{docs[0].page_content}"
        
        # 採点の実行
        result = chain.invoke({
            "problem": request.problem,
            "answer": request.answer,
            "reference_answer": reference_answer
        })
        
        return {
            "feedback": result["text"],
            "reference": reference_answer
        }
    except Exception as e:
        print("エラー内容:", e)
        print(traceback.format_exc())
        raise HTTPException(status_code=500, detail=str(e))

class SaveExampleRequest(BaseModel):
    problem: str
    answer: str
    explanation: str

@app.post("/save_example")
async def save_example(req: SaveExampleRequest):
    try:
        entry = f"問題: {req.problem}\n解答例1: {req.answer}\n解説: {req.explanation}\n\n"
        file_path = ROOT_DIR / "assets/sample_answers.txt"
        with open(file_path, "a", encoding="utf-8") as f:
            f.write(entry)
        return {"status": "success"}
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))

def cosine_similarity(a, b):
    return np.dot(a, b) / (np.linalg.norm(a) * np.linalg.norm(b))

if __name__ == "__main__":
    import uvicorn
    uvicorn.run(app, host="0.0.0.0", port=8000) 