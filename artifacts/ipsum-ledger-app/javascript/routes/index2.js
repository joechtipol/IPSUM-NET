module.exports = {
    getHomePage: (req, res) => {
        let query = "SELECT * FROM `players` ORDER BY id ASC"; // query database to get all the players

        // execute query
        db.query(query, (err, result) => {
            if (err) {
                res.redirect('/');
            }
            console.log(`Index old, result is: ${result.toString()}`);

            res.render('index2.ejs', {
                title: "Welcome to Socka | View Players"
                ,players: result
            });

        });
    },
};