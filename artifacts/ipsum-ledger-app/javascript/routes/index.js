module.exports = {
		getHomePageBlockchain: (req, res) => {
			
		queryWallet().then((result) =>res.render('index.ejs', {
	            title: "Welcome to IpsumLedger Admin | View and Add digital credentials"
	            ,digitalCredentials: result
	        }));
		
			/*
		async() => {
			
			result=await queryWallet();
			res.render('index.ejs', {
	            title: "Welcome to Socka | View Players"
	            ,digitalCredentials: result
	        });
			
			
			
			queryWallet('', (err, result) => {
	            if (err) {
	                res.redirect('/');
	            }
	            console.log(`Index old, result is: ${result.toString()}`);

	            res.render('index2.ejs', {
	                title: "Welcome to Socka | View Digital Credentials"
	                ,digitalCredentials: result
	            });

	        });
			
		}*/
		
    },
};



async function queryWallet() {
    try {

    	const path = require('path');

    	const IPFS =require('ipfs');
        // Create a new file system based wallet for managing identities.
    	const { FileSystemWallet, Gateway } = require('fabric-network');
    	const fs = require('fs');

    	const ccpPath = path.resolve(__dirname, '..','..', 'javascript', 'scriptum.json');
    	const ccpJSON = fs.readFileSync(ccpPath, 'utf8');
    	const ccp = JSON.parse(ccpJSON);

        const walletPath = path.join(process.cwd(), 'wallet');
        const wallet = new FileSystemWallet(walletPath);
        console.log(`Wallet path: ${walletPath}`);

        // Check to see if we've already enrolled the user.
        /*
        const userExists = await wallet.exists('user1');
        if (!userExists) {
            console.log('An identity for the user "user1" does not exist in the wallet');
            console.log('Run the registerUser.js application before retrying');
            return;
        }*/

        // Create a new gateway for connecting to our peer node.
        const gateway = new Gateway();
        await gateway.connect(ccp, { wallet, identity: 'admin', discovery: { enabled: false } });

        // Get the network (channel) our contract is deployed to.
        const network = await gateway.getNetwork('scriptum');

        // Get the contract from the network.
        const contract = network.getContract('ipsumcc');

        // Evaluate the specified transaction.
        // queryCar transaction - requires 1 argument, ex: ('queryCar', 'CAR4')
        // queryAllCars transaction - requires no arguments, ex: ('queryAllCars')
        const result = await contract.evaluateTransaction('queryAllStudentsCredential');
        console.log(`Transaction has been evaluated, result is: ${result.toString()}`);
        return result;

    } catch (error) {
        console.error(`Failed to evaluate transaction: ${error}`);
        //process.exit(1);
    }
}
