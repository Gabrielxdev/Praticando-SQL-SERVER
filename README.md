#  Análise de Histórico Salarial com SQL

Este projeto utiliza **CTEs (Common Table Expressions)** e funções de janela do SQL Server para analisar a evolução salarial de funcionários ao longo do tempo.  

A partir de duas tabelas (`employees` e `salary_history`), a consulta SQL gera uma visão consolidada por colaborador, respondendo a perguntas como:

-  **Qual é o salário mais recente de cada funcionário?**  
-  **Quantas promoções cada funcionário recebeu?**  
-  **Qual foi o maior aumento percentual entre mudanças salariais?**  
-  **O funcionário já teve redução salarial?**  
-  **Qual é a média de meses entre mudanças de salário?**  
-  **Quem teve maior crescimento proporcional (do primeiro ao último salário)?**

##  Principais recursos do código

- Uso de **CTEs** para quebrar a lógica em etapas compreensíveis.  
- **Funções de janela** como `ROW_NUMBER`, `RANK`, `LAG`, `LEAD` para manipulação de linhas ao longo do tempo.  
- Cálculo de indicadores-chave de crescimento salarial.  
- Montagem de um **ranking final** baseado na razão entre o último e o primeiro salário de cada funcionário.  

##  Estrutura das tabelas

### `employees`
- `employee_id` (chave primária)  
- `name`  
- `hire_date`  
- `department`  

### `salary_history`
- `employee_id` (chave estrangeira para `employees`)  
- `change_date`  
- `salary`  
- `promotion` (`Yes` / `No`)  

##  Resultado esperado

A query retorna uma tabela final consolidada com as seguintes colunas:

- `employee_id`  
- `name`  
- `latest_salary`  
- `no_of_promotions`  
- `max_salary_growth`  
- `never_decreased` (`Y`/`N`)  
- `avg_months_between_changes`  
- `RankByGrowth`  

Esse relatório é uma ótima forma de praticar **SQL analítico**, explorando CTEs, funções de janela e agregações para responder a perguntas de negócio reais.
