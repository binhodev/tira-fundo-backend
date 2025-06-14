# 🚀 Deploy Rápido - 5 Minutos

## 1. Gerar Token GitHub (1 min)

-   Vá em GitHub → Settings → Developer Settings → Personal Access Tokens
-   Crie token com permissão `repo`
-   **Copie o token!**

## 2. No seu servidor (2 min)

```bash
# Baixar script
wget https://raw.githubusercontent.com/SEU_USUARIO/tira-fundo-backend/main/deploy-simple.sh
chmod +x deploy-simple.sh

# Editar configurações
nano deploy-simple.sh
```

**Altere apenas esta linha:**

```bash
GITHUB_REPO="https://SEU_TOKEN@github.com/SEU_USUARIO/tira-fundo-backend.git"
```

## 3. Executar Deploy (2 min)

```bash
sudo ./deploy-simple.sh
```

## 4. Pronto! ✅

-   Aplicação rodando em: `http://SEU_SERVIDOR:8000`
-   Para atualizar: execute `sudo ./deploy-simple.sh` novamente

---

## 🔄 Workflow Diário

1. **Desenvolva** no seu computador
2. **Commit & Push** para GitHub
3. **Execute** `sudo ./deploy-simple.sh` no servidor
4. **Aplicação atualizada!**

**Simples assim!** 🎉
