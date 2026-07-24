Fridge Fit Chef - Share with family
====================================

Method 1: Send the app (recommended)
1. Zip this folder and send via WeChat
2. On phone: open fridge-fit-chef.html in Safari/Chrome
   - iPhone: Files app -> tap html -> Open in Safari
   - Android: File manager -> tap html -> Chrome

Method 2: Same fridge via room code
1. You: My tab -> Room code -> Copy share
2. Send the text to mom on WeChat
3. Mom: My tab -> Enter room code -> Join
4. With Supabase configured (see README), inventory syncs automatically

Method 3: WeChat JSON file (no cloud)
1. You: My -> Export fridge -> get 冰箱分享-xxxxx.json
2. Send file on WeChat
3. Mom: My -> Import fridge -> pick file

Method 4: Same WiFi (optional)
Run on PC: python -m http.server 8765
Phone browser: http://YOUR_PC_IP:8765/fridge-fit-chef.html

See README.md for Supabase setup.
