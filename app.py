from flask import Flask, request, render_template_string

app = Flask(__name__)

@app.route("/")
def home():
    # Deliberate input vulnerability (XSS) to test security tools
    user_input = request.args.get('name', 'Guest')
    html_template = f"<h1>Welcome to the DevSecOps Lab, {user_input}!</h1>"
    return render_template_string(html_template)

if __name__ == "__main__":
    # Deliberate flaw: debug=True allows arbitrary remote code execution on crash
    app.run(host="0.0.0.0", port=5000, debug=True)

