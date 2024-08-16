import requests
from bs4 import BeautifulSoup
import urllib.parse
from urllib.parse import urljoin
import csv
from time import sleep

def get_urls(date):
    page_number = 1
    urls = []

    while True:
        url = "https://www.newssite.com/archive/{}?page={}".format(date, page_number)
        response = requests.get(url)
        if response.status_code == 200:
            soup = BeautifulSoup(response.content, 'html.parser')
            links = soup.find_all('a', class_='link_overlay')
            if links:
                urls.extend([urllib.parse.unquote(link.get('href')) for link in links])
                page_number += 1
            else:
                break
        else:
            print("Failed to fetch URLs from {}. Status code: {}".format(url, response.status_code))
            break
    
    return urls

def scrape_data(url):
    base_url = "https://www.newssite.com"
    full_url = urljoin(base_url, url)
    
    response = requests.get(full_url)
    if response.status_code == 200:
        soup = BeautifulSoup(response.content, 'html.parser')
        title = soup.find('h1', class_='title').text.strip()
        author = soup.find('span', class_='name').text.strip()
        upload_time = soup.find('span', class_='tts_time')['content']
        date, time = upload_time.split('T')  # Split date and time
        # Extracting only hours and minutes
        time = time.split('+')[0]  # Removing timezone offset
        time = time[:5]  # Keeping only hours and minutes
        # Counting words in the article body
        article_body = soup.find('div', class_='viewport').text.strip()
        word_count = len(article_body.split())
        # Scrape content tags
        tags_container = soup.find('div', class_='content_tags')
        if tags_container:
            tags = [tag.text.strip() for tag in tags_container.find_all('a')]
        else:
            tags = []
        # Scrape category names
        categories_container = soup.find('div', class_='breadcrumb')
        if categories_container:
            category_names = [category.text.strip() for category in categories_container.find_all('a')[1:]]  # Exclude the first category which is 'Home'
        else:
            category_names = []
        initials = soup.find('div', class_='initials').text.strip()
        return date, time, title, author, ', '.join(category_names), ', '.join(tags), word_count, initials, full_url  # Return category names along with other data
    else:
        print("Failed to fetch data from {}. Status code: {}".format(full_url, response.status_code))
        return None, None, None, None, None, None, None, None, None

def main():
    date = "2024-04-17"
    urls = get_urls(date)
    total_urls = len(urls)
    
    with open('newsdata.csv', 'w', newline='', encoding='utf-8-sig') as csvfile:  # Specified encoding
        fieldnames = ['Date', 'Time', 'Title', 'Author', 'Categories', 'Tags', 'Word Count', 'Initials', 'URL']  # Updated field names
        writer = csv.DictWriter(csvfile, fieldnames=fieldnames)
        writer.writeheader()
        
        for i, url in enumerate(urls, start=1):
            print("Scraping data {}/{}".format(i, total_urls))
            date, time, title, author, categories, tags, word_count, initials, full_url = scrape_data(url)  # Updated function call
            
            if title:
                writer.writerow({'Date': date, 'Time': time, 'Title': title, 'Author': author,  # Updated row
                                 'Categories': categories, 'Tags': tags, 'Word Count': word_count,
                                 'Initials': initials, 'URL': full_url})
            
            # Adding a 5-second gap between requests
            sleep(5)

if __name__ == "__main__":
    main()
