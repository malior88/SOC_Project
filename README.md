# SOC_Project

This project was developed as part of the **NX220** cybersecurity unit, focusing on offensive security techniques.

## 📌 Description

The script provides a menu-driven interface to simulate 3 classic network attacks:

1. **ARP Spoofing** – Sends forged ARP replies to poison a victim’s ARP table.
2. **Brute-force SSH** – Attempts to crack SSH credentials using `medusa` and a password list.
3. **DoS (SYN Flood)** – Floods a remote target with TCP SYN packets using `hping3`.

Each attack is logged with timestamp and target IP to `/var/log/attack_log.log`.

## 🛠️ Tools Used

- `bash`
- `nmap`, `arpspoof`, `medusa`, `hping3`
- Kali Linux & Metasploitable2 as test environment

## 📂 Files

- `773632.s23.nx220.sh` – Main project script
- `773632.s23.nx220.pdf` – Documentation and screenshots

## 📅 Author

**Lior Maman** – Student ID: s23 – Program Code: NX220
