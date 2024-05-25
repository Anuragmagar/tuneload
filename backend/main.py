from flask import Flask, request
import subprocess
from flask_cors import CORS

app = Flask(__name__)
CORS(app)

@app.route("/", methods=['POST'])
def hello_world():
    # print('hee')
    song_url = request.form.get("song_url")
    print(song_url)
    try:
        out = subprocess.run(['spotdl', 'url', song_url], capture_output=True)

        # print(out.stdout.decode())
        words = out.stdout.decode().split()
        download_url = ' '.join(words[3:])

        print(download_url)
        return download_url
    except Exception as e:
        return str(e), 500

if __name__ == '__main__':
    app.run(debug=True)