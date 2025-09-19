/*****************************************************************************************
 Autor.......: Cristiano De godoi
 Data........: 2025-08-17
 Projeto.....: Criação de PROJETO DATA WAREHOUSE - VENDAS
 Banco.......: SQL Server-2021
 Curso Yto Inhon Treinamentos
******************************************************************************************/

-- 1) Criar banco de dados
IF DB_ID(N'SalesDW_Cristiano') IS NULL
BEGIN
    CREATE DATABASE SalesDW_Cristiano;
END;
GO

USE SalesDW_Cristiano;
GO

CREATE TABLE staging.sales_raw (
    ORDERNUMBER INT,
    QUANTITYORDERED INT,
    PRICEEACH DECIMAL(18,2),
    ORDERLINENUMBER INT,
    SALES DECIMAL(18,2),
    ORDERDATE VARCHAR(50),
    STATUS VARCHAR(50),
    QTR_ID INT,
    MONTH_ID INT,
    YEAR_ID INT,
    PRODUCTLINE VARCHAR(50),
    MSRP DECIMAL(18,2),
    PRODUCTCODE VARCHAR(50),
    CUSTOMERNAME VARCHAR(100),
    PHONE VARCHAR(50),
    ADDRESSLINE1 VARCHAR(120),
    ADDRESSLINE2 VARCHAR(120),
    CITY VARCHAR(60),
    STATE VARCHAR(60),
    POSTALCODE VARCHAR(20),
    COUNTRY VARCHAR(60),
    TERRITORY VARCHAR(60),
    CONTACTLASTNAME VARCHAR(60),
    CONTACTFIRSTNAME VARCHAR(60),
    DEALSIZE VARCHAR(20)
);
GO

-- 2) Criar schema de staging (boas práticas)
IF NOT EXISTS (SELECT 1 FROM sys.schemas WHERE name = N'staging')
    EXEC('CREATE SCHEMA staging');
GO

-- 3) Criar tabela de staging compatível com o CSV
IF OBJECT_ID(N'staging.sales_raw','U') IS NOT NULL
    DROP TABLE staging.sales_raw;
GO

--------------------------------------------------------------
-- 4. CRIANDO AS  DIMENSÕES PARA BANCO
--------------------------------------------------------------

-- Dimensão Cliente
CREATE TABLE DimCliente (
    ClienteID INT IDENTITY(1,1) PRIMARY KEY,
    NomeCliente VARCHAR(100),
    Telefone VARCHAR(50),
    Cidade VARCHAR(50),
    Estado VARCHAR(50),
    Pais VARCHAR(50),
    CodigoPostal VARCHAR(20),
    ContatoNome VARCHAR(100)
);

-- Dimensão Produto
CREATE TABLE DimProduto (
    ProdutoID INT IDENTITY(1,1) PRIMARY KEY,
    CodigoProduto VARCHAR(50),
    LinhaProduto VARCHAR(50),
    MSRP DECIMAL(10,2)
);
GO

-- Dimensão Tempo
CREATE TABLE DimTempo (
    TempoID INT IDENTITY(1,1) PRIMARY KEY,
    DataPedido DATE,
    Ano INT,
    Mes INT,
    Trimestre INT
);
GO

-- Dimensão Local (País/Território)
CREATE TABLE DimLocal (
    LocalID INT IDENTITY(1,1) PRIMARY KEY,
    Pais VARCHAR(50),
    Territorio VARCHAR(50)
);
GO

--------------------------------------------------------------
-- 5. TABELA FATO
--------------------------------------------------------------
CREATE TABLE FatoVendas (
    FatoID BIGINT IDENTITY(1,1) PRIMARY KEY,
    ClienteID INT,
    ProdutoID INT,
    TempoID INT,
    LocalID INT,
    NumeroPedido INT,
    Quantidade INT,
    PrecoUnitario DECIMAL(10,2),
    ValorTotal DECIMAL(12,2),
    StatusPedido VARCHAR(50),
    DealSize VARCHAR(20),

    FOREIGN KEY (ClienteID) REFERENCES DimCliente(ClienteID),
    FOREIGN KEY (ProdutoID) REFERENCES DimProduto(ProdutoID),
    FOREIGN KEY (TempoID) REFERENCES DimTempo(TempoID),
    FOREIGN KEY (LocalID) REFERENCES DimLocal(LocalID)
);
GO

--------------------------------------------------------------
-- 6. POPULAR DIMENSÕES (DISTINTOS DA STAGING)
--------------------------------------------------------------

-- Clientes
INSERT INTO DimCliente (NomeCliente, Telefone, Cidade, Estado, Pais, CodigoPostal, ContatoNome)
SELECT DISTINCT
    LTRIM(RTRIM(CUSTOMERNAME)),
    LTRIM(RTRIM(PHONE)),
    LTRIM(RTRIM(CITY)),
    LTRIM(RTRIM(STATE)),
    LTRIM(RTRIM(COUNTRY)),
    LTRIM(RTRIM(POSTALCODE)),
    LTRIM(RTRIM(CONTACTFIRSTNAME)) + ' ' + LTRIM(RTRIM(CONTACTLASTNAME))
FROM staging_sales;

-- Produtos
INSERT INTO DimProduto (CodigoProduto, LinhaProduto, MSRP)
SELECT DISTINCT
    LTRIM(RTRIM(PRODUCTCODE)),
    LTRIM(RTRIM(PRODUCTLINE)),
    MSRP
FROM staging_sales;

-- Tempo
-- Inserir datas válidas considerando múltiplos formatos
INSERT INTO DimTempo (DataPedido, Ano, Mes, Trimestre)
SELECT DISTINCT
    COALESCE(
        TRY_CONVERT(DATE, ORDERDATE, 103), -- dd/mm/yyyy
        TRY_CONVERT(DATE, ORDERDATE, 120), -- yyyy-mm-dd
        TRY_CONVERT(DATE, ORDERDATE, 112)  -- yyyymmdd
    ) AS DataPedido,
    YEAR_ID,
    MONTH_ID,
    QTR_ID
FROM staging_sales
WHERE COALESCE(
        TRY_CONVERT(DATE, ORDERDATE, 103),
        TRY_CONVERT(DATE, ORDERDATE, 120),
        TRY_CONVERT(DATE, ORDERDATE, 112)
    ) IS NOT NULL;

-- Identificar linhas que não foram convertidas
SELECT *
FROM staging_sales
WHERE COALESCE(
        TRY_CONVERT(DATE, ORDERDATE, 103),
        TRY_CONVERT(DATE, ORDERDATE, 120),
        TRY_CONVERT(DATE, ORDERDATE, 112)
    ) IS NULL;

-- Local
INSERT INTO DimLocal (Pais, Territorio)
SELECT DISTINCT
    LTRIM(RTRIM(COUNTRY)),
    LTRIM(RTRIM(TERRITORY))
FROM staging_sales;

--------------------------------------------------------------
-- 7. POPULAR FATO VENDAS (COM JOIN NAS DIMENSÕES)
--------------------------------------------------------------
WITH SalesValidas AS (
    SELECT *,
        COALESCE(
            TRY_CONVERT(DATE, ORDERDATE, 103), -- dd/mm/yyyy
            TRY_CONVERT(DATE, ORDERDATE, 120), -- yyyy-mm-dd
            TRY_CONVERT(DATE, ORDERDATE, 112)  -- yyyymmdd
        ) AS ORDERDATE_CONVERTIDA
    FROM staging_sales
)
INSERT INTO FatoVendas (ClienteID, ProdutoID, TempoID, LocalID, NumeroPedido, Quantidade, PrecoUnitario, ValorTotal, StatusPedido, DealSize)
SELECT
    C.ClienteID,
    P.ProdutoID,
    T.TempoID,
    L.LocalID,
    S.ORDERNUMBER,
    S.QUANTITYORDERED,
    S.PRICEEACH,
    S.SALES,
    LTRIM(RTRIM(S.STATUS)),
    LTRIM(RTRIM(S.DEALSIZE))
FROM SalesValidas S
    INNER JOIN DimCliente C ON C.NomeCliente = LTRIM(RTRIM(S.CUSTOMERNAME))
    INNER JOIN DimProduto P ON P.CodigoProduto = LTRIM(RTRIM(S.PRODUCTCODE))
    INNER JOIN DimTempo T ON T.DataPedido = S.ORDERDATE_CONVERTIDA
    INNER JOIN DimLocal L ON L.Pais = LTRIM(RTRIM(S.COUNTRY))
WHERE S.ORDERDATE_CONVERTIDA IS NOT NULL;

--------------------------------------------------------------
-- 8. VIEWS ANALÍTICAS (PRONTAS PARA POWER BI)
--------------------------------------------------------------

-- Top 10 vendas
CREATE VIEW vw_Top10Vendas AS
SELECT TOP 10
    F.NumeroPedido,
    C.NomeCliente,
    P.LinhaProduto,
    F.ValorTotal
FROM FatoVendas F
    INNER JOIN DimCliente C ON F.ClienteID = C.ClienteID
    INNER JOIN DimProduto P ON F.ProdutoID = P.ProdutoID
ORDER BY F.ValorTotal DESC;
GO

-- Vendas por País
CREATE VIEW vw_VendasPorPais AS
SELECT
    L.Pais,
    SUM(F.ValorTotal) AS TotalVendas
FROM FatoVendas F
    INNER JOIN DimLocal L ON F.LocalID = L.LocalID
GROUP BY L.Pais;
GO

-- Consultar as views
SELECT *
FROM vw_VendasPorPais
ORDER BY TotalVendas DESC;


-- Vendas por Linha de Produto
CREATE VIEW vw_VendasPorProduto AS
SELECT
    P.LinhaProduto,
    SUM(F.ValorTotal) AS TotalVendas
FROM FatoVendas F
    INNER JOIN DimProduto P ON F.ProdutoID = P.ProdutoID
GROUP BY P.LinhaProduto;
GO

-- Consultar a view

SELECT *
FROM vw_VendasPorProduto
ORDER BY TotalVendas DESC;

-- Status dos Pedidos
CREATE VIEW vw_StatusPedidos AS
SELECT
    F.StatusPedido,
    COUNT(*) AS TotalPedidos
FROM FatoVendas F
GROUP BY F.StatusPedido;
GO

-- Status dos Pedidos
SELECT *
FROM vw_StatusPedidos
ORDER BY TotalPedidos DESC;

--------------------------------------------------------------
-- 9. TESTES
--------------------------------------------------------------

-- Conferir dimensões
SELECT TOP 10 * FROM DimCliente;
SELECT TOP 10 * FROM DimProduto;
SELECT TOP 10 * FROM DimTempo;
SELECT TOP 10 * FROM DimLocal;

-- Conferir fato
SELECT TOP 10 * FROM FatoVendas;

-- Conferir views
SELECT * FROM vw_Top10Vendas;
SELECT * FROM vw_VendasPorPais;
SELECT * FROM vw_VendasPorProduto;
SELECT * FROM vw_StatusPedidos;

