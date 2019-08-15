/*
 * Licensed to the Apache Software Foundation (ASF) under one
 * or more contributor license agreements.  See the NOTICE file
 * distributed with this work for additional information
 * regarding copyright ownership.  The ASF licenses this file
 * to you under the Apache License, Version 2.0 (the
 * "License"); you may not use this file except in compliance
 * with the License.  You may obtain a copy of the License at
 *
 * http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing,
 * software distributed under the License is distributed on an
 * "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY
 * KIND, either express or implied.  See the License for the
 * specific language governing permissions and limitations
 * under the License.
 */

/*
 * The sample smart contract for documentation topic:
 * Writing Your First Blockchain Application
 */

package main

/* Imports
 * 4 utility libraries for formatting, handling bytes, reading and writing JSON, and string manipulation
 * 2 specific Hyperledger Fabric specific libraries for Smart Contracts
 */
import (
	"bytes"
	"encoding/json"
	"fmt"

	"github.com/hyperledger/fabric/core/chaincode/shim"
	sc "github.com/hyperledger/fabric/protos/peer"
)

// Define the Smart Contract structure
type SmartContract struct {
}


// Define the StudentCredential structure, with 4 properties.  Structure tags are used by encoding/json library
type StudentCredential struct {
	ID_STUDENT   string `json:"id_student"`
	FIRST_NAME   string `json:"first_name"`
	LAST_NAME  string `json:"last_name"`
	BIRTH_DATE string `json:"birth_date"`
	NATIONALITY  string `json:"nationality"`
	PROGRAM_NAME   string `json:"program_name"`
	SCORE string `json:"score"`
	ATTRIBUTION_DATE   string `json:"attribution_date"`
	HASH_CONTENT   string `json:"hash_content"`
}


/*
 * The Init method is called when the Smart Contract "fabcar" is instantiated by the blockchain network
 * Best practice is to have any Ledger initialization in separate function -- see initLedger()
 */
func (s *SmartContract) Init(APIstub shim.ChaincodeStubInterface) sc.Response {
	return shim.Success(nil)
}

/*
 * The Invoke method is called as a result of an application request to run the Smart Contract "fabcar"
 * The calling application program has also specified the particular smart contract function to be called, with arguments
 */
func (s *SmartContract) Invoke(APIstub shim.ChaincodeStubInterface) sc.Response {

	// Retrieve the requested Smart Contract function and arguments
	function, args := APIstub.GetFunctionAndParameters()
	// Route to the appropriate handler function to interact with the ledger appropriately
	if function == "queryStudentCredential" {
		return s.queryStudentCredential(APIstub, args)
	} else if function == "initLedger" {
		return s.initLedger(APIstub)
	} else if function == "addStudentCredential" {
		return s.addStudentCredential(APIstub, args)
	} else if function == "queryAllStudentsCredential" {
		return s.queryAllStudentsCredential(APIstub)
	}

	return shim.Error("Invalid Smart Contract function name.")
}

func (s *SmartContract) queryStudentCredential(APIstub shim.ChaincodeStubInterface, args []string) sc.Response {

	if len(args) != 1 {
		return shim.Error("Incorrect number of arguments. Expecting 1")
	}

	sudentAsBytes, _ := APIstub.GetState(args[0])
	return shim.Success(sudentAsBytes)
}

func (s *SmartContract) initLedger(APIstub shim.ChaincodeStubInterface) sc.Response {
	
	students := []StudentCredential{
		StudentCredential{ID_STUDENT: "00000001", FIRST_NAME: "Prius", LAST_NAME: "Andrei", BIRTH_DATE: "23/01/1999", NATIONALITY: "FRANCE",PROGRAM_NAME: "Computer science",SCORE: "730",ATTRIBUTION_DATE: "06/08/2019",HASH_CONTENT:"QmWnCctQqpde2HUUrHRq7qY5u8rWZkYw5xhqk5ZgTvdWsd"},
	}

	i := 0
	for i < len(students) {
		fmt.Println("i is ", i)
		studentAsBytes, _ := json.Marshal(students[i])
		APIstub.PutState("STD_"+students[i].ID_STUDENT, studentAsBytes)
		fmt.Println("Added", students[i])
		i = i + 1
	}

	return shim.Success(nil)
}

func (s *SmartContract) addStudentCredential(APIstub shim.ChaincodeStubInterface, args []string) sc.Response {

	if len(args) < 5 {
		return shim.Error("Incorrect number of arguments. Expecting 5")
	}

	var student = StudentCredential{ID_STUDENT: args[0], FIRST_NAME: args[1], LAST_NAME: args[2], BIRTH_DATE: args[3], NATIONALITY: args[4],PROGRAM_NAME: args[5],SCORE: args[6],ATTRIBUTION_DATE: args[7],HASH_CONTENT: args[8]}

	studentAsBytes, _ := json.Marshal(student)
	APIstub.PutState("STD_"+args[0], studentAsBytes)

	return shim.Success(nil)
}

func (s *SmartContract) queryAllStudentsCredential(APIstub shim.ChaincodeStubInterface) sc.Response {

	startKey := "STD_00000000"
	endKey := "STD_99999999"

	resultsIterator, err := APIstub.GetStateByRange(startKey, endKey)
	if err != nil {
		return shim.Error(err.Error())
	}
	defer resultsIterator.Close()

	// buffer is a JSON array containing QueryResults
	var buffer bytes.Buffer
	buffer.WriteString("[")

	bArrayMemberAlreadyWritten := false
	for resultsIterator.HasNext() {
		queryResponse, err := resultsIterator.Next()
		if err != nil {
			return shim.Error(err.Error())
		}
		// Add a comma before array members, suppress it for the first array member
		if bArrayMemberAlreadyWritten == true {
			buffer.WriteString(",")
		}
		buffer.WriteString("{\"Key\":")
		buffer.WriteString("\"")
		buffer.WriteString(queryResponse.Key)
		buffer.WriteString("\"")

		buffer.WriteString(", \"Record\":")
		// Record is a JSON object, so we write as-is
		buffer.WriteString(string(queryResponse.Value))
		buffer.WriteString("}")
		bArrayMemberAlreadyWritten = true
	}
	buffer.WriteString("]")

	fmt.Printf("- queryAllStudents:\n%s\n", buffer.String())

	return shim.Success(buffer.Bytes())
}


// The main function is only relevant in unit test mode. Only included here for completeness.
func main() {

	// Create a new Smart Contract
	err := shim.Start(new(SmartContract))
	if err != nil {
		fmt.Printf("Error creating new Smart Contract: %s", err)
	}
}
