# 📦 Projeto: Data Warehouse - Vendas

Este repositório contém a estrutura completa de um projeto de **Data Warehouse** voltado para análise de vendas, desenvolvido por **Cristiano De Godoi** durante o curso da **Yto Inhon Treinamentos**.

> 🗓️ **Data de criação:** 17/08/2025  
> 🧠 **Banco de dados:** SQL Server 2021

---

## 🚀 Objetivo

Criar uma base analítica robusta para suportar decisões estratégicas de negócio, utilizando modelagem dimensional e boas práticas de engenharia de dados.

---

## 🧱 Estrutura do Projeto

- **Schema `staging`**: área de preparação dos dados brutos  
- **Schema `dw`**: estrutura final com tabelas fato e dimensões

### 🗂️ Tabelas criadas

#### Dimensões
- `dim_cliente`
- `dim_produto`
- `dim_tempo`
- `dim_loja`

#### Fato
- `fato_vendas`

---

## 🛠️ Scripts incluídos

- `create_schema.sql`: Criação dos schemas `staging` e `dw`
- `create_tables.sql`: Criação das tabelas de staging, dimensões e fato
- `load_data.sql`: Exemplo de carga de dados
- `procedures.sql`: Procedures para carga incremental e tratamento de SCD

---

## 📈 Boas práticas aplicadas

- Uso de **chaves substitutas** nas dimensões  
- Controle de **Slowly Changing Dimensions (SCD Tipo 2)**  
- Scripts **idempotentes** para staging  
- Separação clara entre **camadas de ingestão e análise**

---

## 🧪 Como usar

1. Clone o repositório
2. Execute os scripts na ordem:
   - `create_schema.sql`
   - `create_tables.sql`
   - `load_data.sql`
3. Conecte sua ferramenta de BI (ex: Power BI) e comece a explorar!

---

## 📬 Contato

**Cristiano De Godoi**  
📧 cristiano.godoi10@hotmail.com
🔗 [LinkedIn](https://www.linkedin.com/in/cristiano-godoi-franciscano-25508683/)

---
