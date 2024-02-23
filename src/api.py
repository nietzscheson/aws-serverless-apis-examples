from fastapi import FastAPI
from mangum import Mangum
from fastapi.responses import JSONResponse

app = FastAPI()


@app.middleware("http")
async def add_cors_headers(request, call_next):
   response = await call_next(request)
   response.headers["Access-Control-Allow-Origin"] = "*"
   response.headers["Access-Control-Allow-Credentials"] = "true"
   response.headers["Access-Control-Allow-Methods"] = "GET, POST, PUT, DELETE, OPTIONS"
   response.headers["Access-Control-Allow-Headers"] = "Content-Type, Authorization"
   return response

@app.get("/")
def read_root():
   return {"result": "My first FastAPI depolyment using Docker image. With HTTP middleware"}

@app.get("/{text}")
def read_item(text: str):
   return JSONResponse({"result": text})

@app.get("/items/{item_id}")
def read_item(item_id: int):
   return JSONResponse({"result": item_id})

handler = Mangum(app)