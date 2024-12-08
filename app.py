from flask import Flask, request, jsonify
import json
from random import choice, choices, randint, shuffle
from flask_cors import CORS
from hashlib import sha256
import base64
from cryptography.fernet import Fernet
import os

cipher_suite = None
app = Flask(__name__)
CORS(app)

def generate_key_from_passcode(passcode):
    hashed_passcode = sha256(passcode.encode()).digest()[:32]
    return base64.urlsafe_b64encode(hashed_passcode)

def generate_password_adv(letter_count, symbol_count, number_count):
    letters = 'abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ'
    numbers = '0123456789'
    symbols = '!#$%&()*+'

    password_list = (
        choices(letters, k = letter_count) +
        choices(symbols, k = symbol_count) +
        choices(numbers, k = number_count)
    )
    shuffle(password_list)
    return "".join(password_list)

def generate_password():
    letters = 'abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ'
    numbers = '0123456789'
    symbols = '!#$%&()*+'

    password_letters = [choice(letters) for _ in range(randint(8, 10))]
    password_symbols = [choice(symbols) for _ in range(randint(2, 4))]
    password_numbers = [choice(numbers) for _ in range(randint(2, 4))]
    password_list = password_letters + password_symbols + password_numbers

    shuffle(password_list)
    return "".join(password_list)

@app.route('/generate-password-adv', methods=['POST'])
def password_route_adv():
    data = request.json
    print(data)
    letter_count = int(data.get("letter_count"))
    symbol_count = int(data.get("symbol_count"))
    number_count = int(data.get("number_count"))
    password = generate_password_adv(letter_count, symbol_count, number_count)

    return jsonify({'password': password})

@app.route('/generate-password', methods=['GET'])
def password_route():
    password = generate_password()

    return jsonify({'password': password})

@app.route('/get-websites', methods=['GET'])
def get_websites():
    websites_list = {
        "websites": []
    }
    try:
        with open("data.json", "r") as file:
            data = json.load(file)
            for website in data.keys():
                websites_list["websites"].append(website)
        return jsonify(websites_list), 200
    except FileNotFoundError:
        return jsonify({"error": "No data file found"}), 404
    except json.JSONDecodeError:
        return jsonify({"error": "Error decoding JSON"}), 500

@app.route('/save-password', methods=['POST'])
def save_password():
    data = request.json
    website = data.get("website")
    user = data.get("user")
    password = data.get("password")

    encrypted_password = cipher_suite.encrypt(password.encode()).decode()
    new_data = {
        website: {
            "user": user,
            "password": encrypted_password
        }
    }

    try:
        with open("data.json", "r") as file:
            existing_data = json.load(file)
    except (FileNotFoundError, json.JSONDecodeError):
        existing_data = {}

    existing_data.update(new_data)

    with open("data.json", "w") as file:
        json.dump(existing_data, file, indent=4)

    return jsonify({"message": "Password saved successfully!"})


@app.route('/edit-password', methods=['POST'])
def edit_password():
    data = request.json
    website = data.get("website")
    password = data.get("new_password")

    try:
        with open("data.json", "r") as file:
            existing_data = json.load(file)
            if website in existing_data:
                encrypted_password = cipher_suite.encrypt(password.encode()).decode()
                existing_data[website]["password"] = encrypted_password

                with open("data.json", "w") as file:
                    json.dump(existing_data, file, indent=4)
                return jsonify({"message": "Password updated successfully!"}), 200
            else:
                return jsonify({"error": "Website not found"}), 404
    except (FileNotFoundError, json.JSONDecodeError):
        return jsonify({"error": "Error reading data file"}), 500


@app.route('/authenticate', methods=['POST'])
def authenticate():
    global cipher_suite
    data = request.json
    passcode = data.get("passcode")
    key = generate_key_from_passcode(passcode)
    cipher_suite = Fernet(key)

    return jsonify({"message": "Authentication successful"}), 200



@app.route('/search-password', methods=['GET'])
def search_password():
    website = request.args.get('website')
    try:
        with open("data.json", "r") as file:
            data = json.load(file)
            if website in data:
                encrypted_password = data[website]["password"]
                decrypted_password = cipher_suite.decrypt(encrypted_password.encode()).decode()

                data[website]["password"] = decrypted_password
                return jsonify(data[website])
            else:
                return jsonify({"error": "Website not found"}), 404
    except FileNotFoundError:
        return jsonify({"error": "No data file found"}), 404

@app.route('/delete-password', methods=['POST'])
def delete_password():
    website = request.args.get('website')
    try:
        with open("data.json", "r") as file:
            data = json.load(file)
            if website in data:
                del data[website]
                with open("data.json", "w") as file:
                    json.dump(data, file, indent=4)
                return jsonify({"message": "Password deleted successfully!"})
            else:
                return jsonify({"message": "Website not found."})
    except FileNotFoundError:
        return jsonify({"message": "Website not found."})


if __name__ == '__main__':
    app.run(debug=True)
