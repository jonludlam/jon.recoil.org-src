import os
import ollama
from bs4 import BeautifulSoup

def get_html_content(file_path):
    """Extract text content from an HTML file."""
    with open(file_path, 'r', encoding='utf-8') as file:
        html_content = file.read()
    
    # Parse HTML
    soup = BeautifulSoup(html_content, 'html.parser')
    
    # Remove script and style elements
    for script in soup(["script", "style"]):
        script.extract()
    
    # Get text content
    text = soup.get_text(separator=' ', strip=True)
    
    # Remove extra whitespace
    lines = (line.strip() for line in text.splitlines())
    chunks = (phrase.strip() for line in lines for phrase in line.split("  "))
    text = ' '.join(chunk for chunk in chunks if chunk)
    
    return text

def summarize_with_ollama(text, model_name="llama3"):
    """Summarize text using an Ollama model."""
    prompt = f"Please summarize the following text into one line, suitable for the summary field of an rss feed.yn\n{text}"
    
    response = ollama.chat(
        model=model_name,
        messages=[{"role": "user", "content": prompt}]
    )
    
    return response["message"]["content"]

def process_html_files(directory, model_name="llama3"):
    """Process all HTML files in a directory."""
    results = {}
    
    for filename in os.listdir(directory):
        if filename.endswith(".html"):
            file_path = os.path.join(directory, filename)
            print(f"Processing {filename}...")
            
            # Extract text from HTML
            text = get_html_content(file_path)
            
            # Summarize text
            summary = summarize_with_ollama(text, model_name)
            
            results[filename] = summary
            
    return results

# Example usage
if __name__ == "__main__":
    # Directory containing HTML files
    html_directory = "_tmp/html/blog/2025/04"
    
    # Choose your preferred Ollama model
    model = "gemma3"  # or "mistral", "gemma", etc.
    
    summaries = process_html_files(html_directory, model)
    
    # Print summaries
    for filename, summary in summaries.items():
        print(f"\n--- Summary of {filename} ---")
        print(summary)
        print("-" * 50)

