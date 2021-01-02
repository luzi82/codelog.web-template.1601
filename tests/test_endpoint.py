import endpoint
import os
import pytest

@pytest.fixture
def client():
    with endpoint.app.test_client() as client:
        yield client

def test_testme(client):
  v = client.get('/testme').data.decode('utf8')
  assert(v=='testme')
