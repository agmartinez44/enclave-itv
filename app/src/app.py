import os
from flask import Flask, Response, jsonify
from prometheus_client import CONTENT_TYPE_LATEST, Counter, generate_latest

app = Flask(__name__)
healthz_requests = Counter("healthz_requests_total", "Total /healthz requests")


@app.route('/healthz', methods=['GET'])
def health_check():
    healthz_requests.inc()
    return jsonify({'SYS_ENV': os.getenv('SYS_ENV')}), 200


@app.route('/metrics', methods=['GET'])
def metrics():
    return Response(generate_latest(), mimetype=CONTENT_TYPE_LATEST)


if __name__ == '__main__':
    app.run(host='0.0.0.0', port=8080)
