FROM python:3.10.13-bookworm

ENV PYTHONDONTWRITEBYTECODE=1
ENV PYTHONUNBUFFERED=1
ENV DJANGO_SUPERUSER_PASSWORD=12345678

RUN apt-get update && apt-get install -y nginx postgresql postgresql-contrib
RUN pip install Django
RUN pip install psycopg2-binary
RUN pip install gunicorn

COPY settings.py .
COPY nginx.conf /etc/nginx/sites-available/default

EXPOSE 80 8000 5432
CMD service postgresql start && \
sleep 5 && \
su - postgres -c "psql -c 'CREATE DATABASE dj_server_db;'" && \
su - postgres -c "psql -c 'CREATE USER admin WITH PASSWORD '\''admin'\'';'" && \
su - postgres -c "psql -c 'ALTER DATABASE dj_server_db OWNER TO admin;'" && \
django-admin startproject myserver && \
rm myserver/myserver/settings.py && mv settings.py /myserver/myserver/ && \
cd myserver && python manage.py migrate && python manage.py collectstatic && \
python manage.py createsuperuser --noinput --username admin --email admin@example.com && \
gunicorn --bind 0.0.0.0:8000 myserver.wsgi:application && \
["nginx", "-g", "daemon off;"]
#python manage.py runserver 0.0.0.0:8000