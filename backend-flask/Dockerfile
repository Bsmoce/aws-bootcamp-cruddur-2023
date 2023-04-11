FROM 354592008288.dkr.ecr.ca-central-1.amazonaws.com/cruddur-python:3.10-slim-buster

# docker run --rm -p 4567:4567 -it -e FRONTEND_URL='*' -e BACKEND_URL='*' backend-flask

# Inside container
WORKDIR /backend-flask

# Outside container > Inside container
COPY requirements.txt requirements.txt

# Inside container
RUN pip3 install -r requirements.txt

COPY . .


EXPOSE ${PORT}
CMD [ "python3", "-m" , "flask", "run", "--host=0.0.0.0", "--port=4567", "--debug"]