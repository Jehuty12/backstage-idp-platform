#!/usr/bin/env python3
import subprocess
import base64
import hashlib
import sys
import json
from datetime import datetime

# Users and passwords
USERS = {
    'admin': 'AdminPass123!',
    'superviseur': 'SuperPass456!',
    'dev': 'DevPass789!',
    'bob': 'BobReadOnly!@'
}

ARGOCD_NS = 'argocd'

def generate_bcrypt_hash(password):
    """Generate bcrypt hash using python-bcrypt or passlib"""
    try:
        import bcrypt
        salt = bcrypt.gensalt(rounds=10)
        hash_bytes = bcrypt.hashpw(password.encode(), salt)
        return hash_bytes.decode()
    except ImportError:
        # Fallback: use passlib if available
        try:
            from passlib.context import CryptContext
            crypt_context = CryptContext(schemes=["bcrypt"])
            return crypt_context.hash(password)
        except ImportError:
            print("ERROR: Neither bcrypt nor passlib is available!")
            print("Install with: pip install bcrypt")
            sys.exit(1)

def patch_secret(username, password_hash, timestamp):
    """Patch the argocd-secret with new user password"""
    # Create JSON patch for kubectl
    patch = {
        "data": {
            f"accounts.{username}.password": base64.b64encode(password_hash.encode()).decode(),
            f"accounts.{username}.passwordMtime": base64.b64encode(timestamp.encode()).decode()
        }
    }
    
    cmd = [
        "kubectl", "-n", ARGOCD_NS, "patch", "secret", "argocd-secret",
        "--type", "merge", "-p", json.dumps(patch)
    ]
    
    print(f"Patching secret for user: {username}")
    result = subprocess.run(cmd, capture_output=True, text=True)
    
    if result.returncode != 0:
        print(f"ERROR: Failed to patch secret for {username}")
        print(f"  stdout: {result.stdout}")
        print(f"  stderr: {result.stderr}")
        return False
    
    print(f"  ✓ {username} password hash set")
    return True

def main():
    print("=== Generating bcrypt hashes and patching argocd-secret ===\n")
    
    # Generate current timestamp
    timestamp = datetime.utcnow().strftime("%Y-%m-%dT%H:%M:%SZ")
    
    # Process each user
    success_count = 0
    for username, password in USERS.items():
        print(f"Generating hash for {username}...")
        try:
            password_hash = generate_bcrypt_hash(password)
            print(f"  Hash: {password_hash[:20]}...")
            
            if patch_secret(username, password_hash, timestamp):
                success_count += 1
            else:
                print(f"  ✗ Failed to patch {username}")
        except Exception as e:
            print(f"  ✗ Error: {e}")
    
    print(f"\n=== Results ===")
    print(f"Successfully patched: {success_count}/{len(USERS)} users")
    
    if success_count == len(USERS):
        print("\n=== Restarting ArgoCD Server ===")
        result = subprocess.run(
            ["kubectl", "-n", ARGOCD_NS, "rollout", "restart", "deployment/argocd-server"],
            capture_output=True, text=True
        )
        if result.returncode == 0:
            print("Rollout restart initiated")
            
            # Wait for rollout
            result = subprocess.run(
                ["kubectl", "-n", ARGOCD_NS, "rollout", "status", "deployment/argocd-server", "--timeout=5m"],
                capture_output=True, text=True
            )
            if result.returncode == 0:
                print("✓ Rollout completed successfully")
            else:
                print(f"⚠ Rollout status: {result.stdout}")
        else:
            print(f"ERROR: Failed to restart deployment: {result.stderr}")
    
    print("\n=== User Credentials ===")
    for username, password in USERS.items():
        print(f"{username}: {password}")
    
    print("\n✓ ArgoCD users configured successfully!")

if __name__ == "__main__":
    main()
