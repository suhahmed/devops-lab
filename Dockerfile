FROM python:3.9-slim

WORKDIR /app

COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

COPY app.py .

EXPOSE 5000

# Security hardening: Run as non-root user
USER 1000

CMD ["python", "app.py"]

