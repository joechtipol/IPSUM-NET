const express = require('express');
const fileUpload = require('express-fileupload');
const bodyParser = require('body-parser');
const mysql = require('mysql');
const path = require('path');
const app = express();

const {getHomePage} = require('./routes/index2');
const {getHomePageBlockchain} = require('./routes/index');

const {addDigitalCredentialPage, addDigitalCredential} = require('./routes/digital_credential');
const port = 5000;



const { FileSystemWallet, Gateway } = require('fabric-network');
const fs = require('fs');

const ccpPath = path.resolve(__dirname, '..', 'javascript', 'scriptum.json');
const ccpJSON = fs.readFileSync(ccpPath, 'utf8');
const ccp = JSON.parse(ccpJSON);




// create connection to database
// the mysql.createConnection function takes in a configuration object which contains host, user, password and the database name.
const db = mysql.createConnection ({
    host: 'ns331184.ip-37-187-121.eu',
    user: 'root',
    password: '',
    database: 'socka'
});

// connect to database
db.connect((err) => {
    if (err) {
        console.log('Not Connected to database');
    }
    console.log('Connected to database');
});
global.db = db;

// configure middleware
app.set('port', process.env.port || port); // set express to use this port
app.set('views', __dirname + '/views'); // set express to look in this folder to render our view
app.set('view engine', 'ejs'); // configure template engine
app.use(bodyParser.urlencoded({ extended: false }));
app.use(bodyParser.json()); // parse form data client
app.use(express.static(path.join(__dirname, 'public'))); // configure express to use public folder
app.use(fileUpload()); // configure fileupload

// routes for the app

app.get('/app', getHomePageBlockchain);
app.get('/app/blockchain', getHomePageBlockchain);
app.get('/app/add', addDigitalCredentialPage);
app.post('/app/add', addDigitalCredential);


async function initWallet() {
    try {

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
        if(userExists)
        	{
            await gateway.connect(ccp, { wallet, identity: 'user1', discovery: { enabled: false } });

        	}
        else
        	{
            await gateway.connect(ccp, { wallet, identity: 'admin', discovery: { enabled: false } });

        	}

        // Get the network (channel) our contract is deployed to.
        const network = await gateway.getNetwork('scriptum');

        // Get the contract from the network.
        const contract = network.getContract('ipsumcc');

        // Evaluate the specified transaction.
        // queryCar transaction - requires 1 argument, ex: ('queryCar', 'CAR4')
        // queryAllCars transaction - requires no arguments, ex: ('queryAllCars')
        const result = await contract.evaluateTransaction('queryAllStudentsCredential');
        console.log(`Transaction has been evaluated, result is: ${result.toString()}`);

    } catch (error) {
        console.error(`Failed to evaluate transaction: ${error}`);
        process.exit(1);
    }
}

initWallet();
// set the app to listen on the port
app.listen(port, () => {
    console.log(`Server running on port: ${port}`);
});
