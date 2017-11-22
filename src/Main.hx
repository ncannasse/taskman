class Main {

    static function main() {
        if( js.node.Buffer != null ) {
            startServer();
            return;
        }
        new Client();
    }

    static function startServer() {
        var config = haxe.Json.parse(sys.io.File.getContent("config.json"));
        js.node.Http.createServer(function(req,resp) {
            var url = req.url;
            if( url == "/" ) url = "/index.html";
			var baseName = url.split("/").pop();
            if( baseName.indexOf(".") > 0 && url.indexOf("..") < 0 ) {
                try {
					var content = sys.io.File.getBytes("." + url);
					var ext = baseName.split(".").pop().toLowerCase();
					switch( ext ) {
					case "png", "jpg", "jpeg", "gif":
						resp.setHeader('Content-Type', 'image/' + ext);
					default:
					}
                    resp.end(js.node.Buffer.hxFromBytes(content));
                    return;
                } catch( e : Dynamic ) {
                }
            }
            mongo.MongoClient.connect("mongodb://"+config.host+":"+config.port+"/"+config.db,function(err,db) {
                function onError(err:Dynamic) {
                    if( db != null ) db.close();
                    resp.end("<pre>"+StringTools.htmlEscape(err+haxe.CallStack.toString(haxe.CallStack.exceptionStack()))+"</pre");
                }
                function onResult(err,result:Dynamic) {
                    if( err != null ) return onError(err);
                    db.close();
                    Sys.println("< "+ result);
                    resp.end(haxe.Json.stringify(result,"\t"));
                }
                if( err != null ) return onError(err);
                db.authenticate(config.user, config.password, function(err,result) {
                    if( err != null ) return onError(err);
                    var url = js.node.Url.parse(req.url,true);
                    var args = (url.query:Dynamic<String>).args;
                    Sys.println("> "+url.pathname+" "+args);
                    var args : Dynamic = try haxe.Json.parse(args) catch( e : Dynamic ) {};
                    switch( url.pathname ) {
                    case "/find":
                        var col = db.collection(args.collection);
                        col.find(args.filter).toArray(onResult);
                    case "/insert":
                        var col = db.collection(args.collection);
                        col.insertMany([args.obj],function(err,result) if( err != null ) onResult(err,null) else onResult(err,result.insertedIds[0]));
                    case "/insertMany":
                        var col = db.collection(args.collection);
                        col.insertMany(args.objs,function(err,result) if( err != null ) onResult(err,null) else onResult(err,result.insertedIds));
                    case "/delete":
                        var col = db.collection(args.collection);
                        col.deleteMany(args.query,onResult);
					case "/aggregate":
                        var col = db.collection(args.collection);
                        col.aggregate(args.pipeline,{},onResult);
                    default:
                        resp.statusCode = 404;
                        resp.end("Not found");
                    }
                });
            });
        }).listen(8080);
    }

}