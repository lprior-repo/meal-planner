from urllib.parse import urlparse

def main(url: str) -> str:
    domain = urlparse(url).netloc
    # meatchurch.com -> meat-church
    # seriouseats.com -> serious-eats
    return domain.replace("www.", "").replace(".com", "").replace(".", "-")
