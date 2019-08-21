/*
 * SPDX-License-Identifier: Apache-2.0
 */

'use strict';

const { FileSystemWallet, Gateway } = require('fabric-network');
const fs = require('fs');
const path = require('path');
var ipfsAPI = require('ipfs-api');

var ipfs = ipfsAPI('vps471348.ovh.net', '5001'); //leaving out the arguments will default to these values


const ccpPath = path.resolve(__dirname, '..', 'javascript', 'scriptum.json');
const ccpJSON = fs.readFileSync(ccpPath, 'utf8');
const ccp = JSON.parse(ccpJSON);

async function main() {
    try {
        var myArgs = process.argv.slice(2);

        console.log(myArgs);
        const studentCredentials = {
            id_student: myArgs[0],
            first_name: myArgs[1],
            last_name: myArgs[2],
            birth_date: myArgs[3],
            nationality:myArgs[4],
	    program_name: myArgs[5],
            score: myArgs[6],
	    attribution_date: myArgs[7],
        };
       
        

        // Create a new file system based wallet for managing identities.
        const walletPath = path.join(process.cwd(), 'wallet');
        const wallet = new FileSystemWallet(walletPath);
        console.log(`Wallet path: ${walletPath}`);

        // Check to see if we've already enrolled the user.
        const userExists = await wallet.exists('user1');
        if (!userExists) {
            console.log('An identity for the user "user1" does not exist in the wallet');
            console.log('Run the registerUser.js application before retrying');
           // return;
        }

        // Create a new gateway for connecting to our peer node.
        const gateway = new Gateway();
        await gateway.connect(ccp, { wallet, identity: 'admin', discovery: { enabled: false } });

        // Get the network (channel) our contract is deployed to.
        const network = await gateway.getNetwork('scriptum');

        // Get the contract from the network.
        const contract = network.getContract('ipsumcc');
        
 const results=await ipfs.files.add(Buffer.from(JSON.stringify(studentCredentials)));
 console.log(results);
const hashContent=results[0].hash;
    

        // Submit the specified transaction.
        // createCar transaction - requires 5 argument, ex: ('createCar', 'CAR12', 'Honda', 'Accord', 'Black', 'Tom')
        // changeCarOwner transaction - requires 2 args , ex: ('changeCarOwner', 'CAR10', 'Dave')
        await contract.submitTransaction('addStudentCredential', myArgs[0], myArgs[1], myArgs[2], myArgs[3], myArgs[4],myArgs[5],myArgs[6],myArgs[7],hashContent);

        



        console.log('Transaction has been submitted');

        // Disconnect from the gateway.
        await gateway.disconnect();

        try {
//  await node.stop()
 // console.log('Node stopped!')
  process.exit();
} catch (error) {
  console.error('Node failed to stop!', error)
}

    } catch (error) {
        console.error(`Failed to submit transaction: ${error}`);
        process.exit(1);
    }
}

main();
