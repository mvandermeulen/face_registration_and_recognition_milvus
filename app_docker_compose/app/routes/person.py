"""
Basic operations for faces
"""
from fastapi import APIRouter

from inference import get_registered_person as get_registered_person_api
from inference import unregister_person as unregister_person_api


router = APIRouter()


@router.get("/person")
def get_all_registered_person():
    return {"TODO: Should return all registered faces and corresponding assigned name"}


@router.get("/person/{person_id}")
def get_registered_person(person_id: int):
    return get_registered_person_api(person_id)


@router.delete("/person/{person_id}")
def unregister_person(person_id: int):
    return unregister_person_api(person_id)
