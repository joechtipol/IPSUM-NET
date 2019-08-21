const fs = require('fs');




module.exports = {
    addDigitalCredentialPage: (req, res) => {
        res.render('add-digital-credential.ejs', {
            title: "Welcome to IpsumLedger | Add a new digital credential"
            ,message: ''
        });
    },
    addDigitalCredential: (req, res) => {
    	
    	
    	invokeTransactionsIpfsBlockchain(req).then((result) =>res.redirect('/app'));
               
    },
    editPlayerPage: (req, res) => {
        let playerId = req.params.id;
        let query = "SELECT * FROM `players` WHERE id = '" + playerId + "' ";
        db.query(query, (err, result) => {
            if (err) {
                return res.status(500).send(err);
            }
            res.render('edit-player.ejs', {
                title: "Edit  Player"
                ,player: result[0]
                ,message: ''
            });
        });
    },
    editPlayer: (req, res) => {
        let playerId = req.params.id;
        let first_name = req.body.first_name;
        let last_name = req.body.last_name;
        let position = req.body.position;
        let number = req.body.number;

        let query = "UPDATE `players` SET `first_name` = '" + first_name + "', `last_name` = '" + last_name + "', `position` = '" + position + "', `number` = '" + number + "' WHERE `players`.`id` = '" + playerId + "'";
        db.query(query, (err, result) => {
            if (err) {
                return res.status(500).send(err);
            }
            res.redirect('/');
        });
    },
    deletePlayer: (req, res) => {
        let playerId = req.params.id;
        let getImageQuery = 'SELECT image from `players` WHERE id = "' + playerId + '"';
        let deleteUserQuery = 'DELETE FROM players WHERE id = "' + playerId + '"';

        db.query(getImageQuery, (err, result) => {
            if (err) {
                return res.status(500).send(err);
            }

            let image = result[0].image;

            fs.unlink(`public/assets/img/${image}`, (err) => {
                if (err) {
                    return res.status(500).send(err);
                }
                db.query(deleteUserQuery, (err, result) => {
                    if (err) {
                        return res.status(500).send(err);
                    }
                    res.redirect('/');
                });
            });
        });
    }
};




async function invokeTransactionsIpfsBlockchain(req) {
    try {

    	
    	var ipfsAPI = require('ipfs-api');

    	var ipfs = ipfsAPI('vps471348.ovh.net', '5001'); //leaving out the arguments will default to these values


    	
    	
    	if (!req.files) {
            return res.status(400).send("No files were uploaded.");
        }

        let message = '';
        let first_name = req.body.first_name;
        let last_name = req.body.last_name;
        let program_name = req.body.position;
        let score = req.body.number;
        let studentId = req.body.student_id;
        let birthDate=req.body.birth_date        
        let nationality=req.body.nationality;
        
        let uploadedFile = req.files.image;
        let image_name = uploadedFile.name;
        let fileExtension = uploadedFile.mimetype.split('/app')[1];
        
        const results=await ipfs.files.add(Buffer.from(uploadedFile.data));
        console.log(results);
       const hashContent=results[0].hash;
        //image_name = username + '.' + fileExtension;
       
     await ipfs.pin.add(hashContent);

    	
    	
    	
    	
    	const path = require('path');

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
        await contract.submitTransaction('addStudentCredential', studentId, first_name, last_name, birthDate,nationality ,program_name,score,"20/08/2019",hashContent);
        console.log('Transaction has been submitted');

    } catch (error) {
        console.error(`Failed to evaluate transaction: ${error}`);
        //process.exit(1);
    }
}
