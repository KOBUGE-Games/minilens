var fs = require("fs");
var os = require("os");
var packs = fs.readdirSync(".");
var packs_file = "";
if(os.platform() !== "linux" && process.argv[2] !== "-f")
{
	console.log("This node.js script hasn't been tested on any platform except linux. ");
	console.log("We detect that you are running another platform. If you want to ");
	console.log("continue, which is quite risky, you should re-run the command with ");
	console.log("the -f flag, like this: ");
	console.log("\t$ node ./make_packs_and_rename.js -f");
}
else
{
	for(var i in packs)
	{
		var stats = fs.statSync("./" + packs[i]);
		if(stats.isDirectory())
		{
			var files = fs.readdirSync("./" + packs[i]);
			var idx = 0;
			for(var f in files)
			{
				if(files[f].search("level") != -1)
				{
					idx = idx + 1;
					console.log("./" + packs[i] + "/" + files[f] + "->" + "./" + packs[i] + "/level_" + idx + ".xml" );
					fs.renameSync("./" + packs[i] + "/" + files[f], "./" + packs[i] + "/level_" + idx + ".xml");
				}
			}
			packs_file += packs[i] + " " + idx + "\n";
			console.log("Finished pack \"" + packs[i] + "\"");
		}
	}
	fs.writeFileSync("packs.txt",packs_file);
	console.log("Wrote \"packs.txt\"");
}
