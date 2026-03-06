# Use an official Python runtime as a parent image
FROM python:3.10-slim-buster

# Set the working directory in the container
WORKDIR /app

# Install system dependencies for sentence-transformers and other libraries
# (تثبيت التبعيات اللازمة لـ sentence-transformers ومكتبات أخرى)
RUN apt-get update && apt-get install -y \
    build-essential \
    git \
    && rm -rf /var/lib/apt/lists/*

# Copy the current directory contents into the container at /app
COPY . /app

# Install any needed packages specified in requirements.txt
# (تثبيت الحزم المطلوبة من requirements.txt)
RUN pip install --no-cache-dir -r requirements.txt

# Expose port 8000 for FastAPI
# (تعريض المنفذ 8000 لتطبيق FastAPI)
EXPOSE 8000

# Run main.py when the container launches
# (تشغيل main.py عند بدء تشغيل الحاوية)
CMD ["uvicorn", "main:app", "--host", "0.0.0.0", "--port", "8000"]
