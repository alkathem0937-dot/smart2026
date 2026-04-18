from setuptools import setup, find_packages

setup(
    name='smartjudi-common',
    version='1.0.0',
    packages=find_packages(),
    install_requires=[
        'djangorestframework',
        'djangorestframework-simplejwt',
        'httpx',
        'redis',
    ],
    description='Shared utilities for SmartJudi microservices',
)
