# Publicar no GitHub

O repositório local usa a branch `main`. Antes de publicar, revise os arquivos com `git status` e escolha a licença do código original (veja `CREDITS.md`).

```bash
cd ~/dark-mountain
python3 scripts/check.py
git add .
git diff --cached --stat
git diff --cached --check
git commit -m "Prepare Dark Mountain rice for GitHub"
```

Se o Git pedir identidade, configure seu nome e e-mail antes do commit. Você pode usar o endereço privado noreply fornecido pelo GitHub.

Crie no GitHub um repositório vazio chamado `dark-mountain`, sem gerar README ou outros arquivos. Troque `SEU_USUARIO` no comando abaixo pelo seu usuário:

```bash
git remote add origin https://github.com/SEU_USUARIO/dark-mountain.git
git push -u origin main
```

Nenhum remoto ou envio é configurado pelos scripts deste projeto. Não inclua históricos de shell, credenciais, backups pessoais ou arquivos de estado. Caches Python e arquivos `.env` são ignorados pelo Git.
