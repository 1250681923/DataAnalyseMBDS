package concessionnaireBase;

import oracle.kv.KVStore;
import java.util.List;
import java.util.Iterator;
import oracle.kv.KVStoreConfig;
import oracle.kv.KVStoreFactory;
import oracle.kv.FaultException;
import oracle.kv.StatementResult;
import oracle.kv.table.TableAPI;
import oracle.kv.table.Table;
import oracle.kv.table.Row;
import oracle.kv.table.PrimaryKey;
import oracle.kv.ConsistencyException;
import oracle.kv.RequestTimeoutException;
import java.lang.Integer;
import oracle.kv.table.TableIterator;
import oracle.kv.table.EnumValue;
import java.io.File;
import java.io.BufferedReader;
import java.io.File;
import java.io.FileInputStream;
import java.io.FileWriter;
import java.io.IOException;
import java.io.InputStream;
import java.io.InputStreamReader;
import java.io.PrintWriter;

import java.util.StringTokenizer;
import java.util.ArrayList;
import java.util.List;



/**
 * Cette classe fournit les fonctions nécessaires pour gérer les tables.
 * La fonction void executeDDL(String statement) reçoit en paramètre 
 * une commande ddl et l'applique dans la base nosql.
 * La displayResult affiche l'état de l'exécution de la commande
 * la fonction createTableClient permet de créer une table client>.
 */

 
 public class ConcessionnaireBase {
    private final KVStore store;
	private final String myTpPath="/home/ZHAO/Projet";
	private final String tabClients="CLIENTS_ORACLE_ZHAO";
	private int clientid = 1;
    /**
     * Runs the DDL command line program.
     */
    public static void main(String args[]) {
        try {
			ConcessionnaireBase conceBase= new ConcessionnaireBase(args);
			conceBase.initConcessionnaireTablesAndData(conceBase);
			//conceBase.getClientRows();

        } catch (RuntimeException e) {
            e.printStackTrace();
        }
    }
    /**
     * Parses command line args and opens the KVStore.
     */
	ConcessionnaireBase(String[] argv) {

		String storeName = "kvstore";
		String hostName = "localhost";
		String hostPort = "5000";

		final int nArgs = argv.length;
		int argc = 0;
		store = KVStoreFactory.getStore
		    (new KVStoreConfig(storeName, hostName + ":" + hostPort));
	}

	
	/**
	* Affichage du résultat pour les commandes DDL (CREATE, ALTER, DROP)
	*/

	private void displayResult(StatementResult result, String statement) {
		System.out.println("===========================");
		if (result.isSuccessful()) {
			System.out.println("Statement was successful:\n\t" +
			statement);
			System.out.println("Results:\n\t" + result.getInfo());
		} else if (result.isCancelled()) {
			System.out.println("Statement was cancelled:\n\t" +
			statement);
		} else {
			/*
			* statement was not successful: may be in error, or may still
			* be in progress.
			*/
			if (result.isDone()) {
				System.out.println("Statement failed:\n\t" + statement);
				System.out.println("Problem:\n\t" +
				result.getErrorMessage());
			}
			else {

				System.out.println("Statement in progress:\n\t" +
				statement);
				System.out.println("Status:\n\t" + result.getInfo());
			}
		}
	}
	public void initConcessionnaireTablesAndData(ConcessionnaireBase conceBase) {
	
		conceBase.createTableClient();
	
		// Ne pas oublier d'inclure le fichier Clients_12.csv ou tout autre ficiher similaire dans le bon répertoire.
		// Load fichier clients 12.
		conceBase.loadClientDataFromFile(myTpPath+"/Data/Clients_12.csv");

	}

/**
		M&thode de suppression de la table Client.
	*/	
	public void dropTableClient() {
		String statement = null;

		statement ="drop table "+tabClients;
		executeDDL(statement);
	}

	public void createTableClient() {
		String statement = null;
		statement = "Create table "+ tabClients +" ("
				+"CLIENTID INTEGER,"
				+"AGE STRING,"
				+"SEXE STRING,"
				+"TAUX STRING,"
				+"SITUATIONFAMILIALE STRING," 
				+"NBENFANTSACHARGE STRING,"
				+"DEUXIEMEVOITURE STRING,"
				+"IMMATRICULATION STRING,"
				+"PRIMARY KEY(CLIENTID))";
		executeDDL(statement);

	}

	


	public void executeDDL(String statement) {
		TableAPI tableAPI = store.getTableAPI();
		StatementResult result = null;
		
		System.out.println("****** Dans : executeDDL ********" );
		try {
		/*
		* Add a table to the database.
		* Execute this statement asynchronously.
		*/
		result = store.executeSync(statement);
		displayResult(result, statement);
		} catch (IllegalArgumentException e) {
		System.out.println("Invalid statement:\n" + e.getMessage());
		} catch (FaultException e) {
		System.out.println("Statement couldn't be executed, please retry: " + e);
		}
	}


	/**
	* insertClientRow : Insère une nouvelle ligne dans la table CLIENT
	*/
	private void insertClientRow(String age, String sexe, String taux, String situationFamiliale,
								  String nbEnfantsACharge, String deuxiemeVoiture, String immatriculation){
		//TableAPI tableAPI = store.getTableAPI();
		StatementResult result = null;
		String statement = null;
		System.out.println("********************************** Dans : insertClientRow *********************************" );

		try {

			TableAPI tableH = store.getTableAPI();
			Table tableClient = tableH.getTable(tabClients);
			
			Row clientRow = tableClient.createRow();

			clientRow.put("clientid", clientid);
			clientRow.put("age", age);
			clientRow.put("sexe", sexe);
			clientRow.put("taux", taux);
			clientRow.put("situationFamiliale", situationFamiliale);
			clientRow.put("nbEnfantsACharge", nbEnfantsACharge);
			clientRow.put("deuxiemeVoiture", deuxiemeVoiture);
			clientRow.put("immatriculation", immatriculation);
			// Insert the row.
			tableH.put(clientRow, null, null);
			clientid++;
		} 
		catch (IllegalArgumentException e) {
			System.out.println("Invalid statement:\n" + e.getMessage());
		} 
		catch (FaultException e) {
			System.out.println("Statement couldn't be executed, please retry: " + e);
		}

	}

	
	/**
	 * loadClientDataFromFile : Charge tous les clients du fichier client.
	 */
	void loadClientDataFromFile(String clientDataFileName){
		InputStreamReader 	ipsr;
		BufferedReader 		br=null;
		InputStream 		ips;
		
		String ligne;
		System.out.println("**************************** Dans : loadClientDataFromFile ***************************" );
		
		try {
			ips  = new FileInputStream(clientDataFileName); 
			ipsr = new InputStreamReader(ips);
			br = new BufferedReader(ipsr);

			// Delete the row with column names
			//br.readLine();

			//int i = 0;
			while ((ligne = br.readLine()) != null) {

				ArrayList<String> clientRecord= new ArrayList<String>();	
				StringTokenizer val = new StringTokenizer(ligne,",");
				//i++;
				while(val.hasMoreTokens()) { 
						clientRecord.add(val.nextToken().toString());
				}
				//int clientid				= Integer.parseInt(clientRecord.get(0));
				String age					= clientRecord.get(0);
				String sexe					= clientRecord.get(1);
				String taux					= clientRecord.get(2);
				String situationFamiliale	= clientRecord.get(3);
				String nbEnfantsACharge		= clientRecord.get(4);
				String deuxiemeVoiture		= clientRecord.get(5);
				String immatriculation		= clientRecord.get(6);

				//this.insertClientRow(clientid, age, sexe, taux, situationFamiliale, nbEnfantsACharge, deuxiemeVoiture, immatriculation);
				this.insertClientRow(age, sexe, taux, situationFamiliale, nbEnfantsACharge, deuxiemeVoiture, immatriculation);
			}
		}
		catch(Exception e){
			e.printStackTrace(); 
		}
	}


	private void displayClientRow (Row clientRow) {
		Integer clientid			= clientRow.get("CLIENTID").asInteger().get();
		String age					= clientRow.get("AGE").asString().get();
		String sexe					= clientRow.get("SEXE").asString().get();
		String taux				= clientRow.get("TAUX").asString().get();
		String situationfamiliale	= clientRow.get("SITUATIONFAMILIALE").asString().get();
		String nbenfantsacharge	= clientRow.get("NBENFANTSACHARGE").asString().get();
		String deuxiemeVoiture		= clientRow.get("DEUXIEMEVOITURE").asString().get();
		String immatriculation		= clientRow.get("IMMATRICULATION").asString().get();

		System.out.println("Client row : { clientid: "+ clientid +" - age: "+ age + " - sexe: "+ sexe +
				" - taux: "+taux+" - situationfamiliale: "+situationfamiliale+" - nbenfantsacharge: "+nbenfantsacharge+
				" - deuxiemeVoiture: " + deuxiemeVoiture +" - immatriculation: "+immatriculation+"}");
	}

	
	public void getClientById(int clientId){
		StatementResult result = null;
		String statement = null;
		System.out.println("\n\n****************************** Dans : getClientById ******************************" );

		try { 
			TableAPI tableH = store.getTableAPI();
			Table tableClient = tableH.getTable(tabClients);

			PrimaryKey key=tableClient.createPrimaryKey();
			key.put("clientId", clientId);
			Row row = tableH.get(key, null);
			displayClientRow(row);
		} catch (IllegalArgumentException e) {
			System.out.println("Invalid statement:\n" + e.getMessage());
		} catch (FaultException e) {
			System.out.println("Statement couldn't be executed, please retry: " + e);
		}
	}

	
	public void getClientRows(){
		TableAPI tableAPI = store.getTableAPI();
		StatementResult result = null;
		String statement = null;
		System.out.println("************************** LISTING DES CLIENTS ************************************* ");

		try {
			TableAPI tableH = store.getTableAPI();
			Table tableClient = tableH.getTable(tabClients);
			PrimaryKey key = tableClient.createPrimaryKey();

			TableIterator<Row> iter = tableH.tableIterator(key, null, null);
			try {
				while (iter.hasNext()) {
					Row clientRow = iter.next();
					displayClientRow(clientRow);
				}
			} finally {
				if (iter != null) {
				iter.close();
			}
			}
		} 
		catch (IllegalArgumentException e) {
			System.out.println("Invalid statement:\n" + e.getMessage());
		} 
		catch (FaultException e) {
			System.out.println("Statement couldn't be executed, please retry: " + e);
		}
	}

	
 }
