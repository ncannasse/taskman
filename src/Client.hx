import js.jquery.Helper.*;

typedef Task = {
    var id : String;
    var text : String;
}

class Client {

    public var tasks : Array<Task>;

    public function new() {
        J("#main").html("Loading...");
        initAdmin();
        mongoFind("tasks",{},function(arr) {
            tasks = cast arr;
            refresh();
        });
    }

    function initAdmin() {
        var text = J("#labelsAdmin textarea");
        J("#labelsAdmin .btn-primary").click(function(e) {
            var objs : Array<Dynamic> = try haxe.Json.parse(text.val()) catch( err : Dynamic ) { displayError(""+err); e.preventDefault(); return; };
            mongoDelete("labels",{},function() {
                mongoInsertMany("labels",objs,function() {
                    untyped J("#labelsAdmin").modal("hide");
                });
            });
        });
        J("[data-target='#labelsAdmin']").click(function(_) {
            text.val("Loading...");
            mongoFind("labels",{},function(arr:Array<Dynamic>) {
                for( o in arr )
                    Reflect.deleteField(o,"_id");
                text.val(haxe.Json.stringify(arr,"\t"));
            });
        });
    }

    function refresh() {
        J("#main").empty();
    }

    function displayError( msg : String ) {
        js.Browser.alert(msg);
    }

    function mongoFind( collection : String, ?filter : {}, onResult : Array<Dynamic> -> Void ) {
        mongoRequest("/find",{collection:collection,filter:filter},onResult);
    }

    function mongoInsert( collection : String, obj : {}, ?onInserted : Void -> Void ) {
        mongoRequest("/insert",{collection:collection,obj:obj},function(id) { Reflect.setField(obj,"_id",id); if( onInserted != null ) onInserted(); });
    }

    function mongoInsertMany( collection : String, objs : Array<Dynamic>, ?onInserted : Void -> Void ) {
        mongoRequest("/insertMany",{collection:collection,objs:objs},function(ids) { for( i in 0...objs.length ) Reflect.setField(objs[i],"_id",ids[i]); if( onInserted != null ) onInserted(); });
    }

    function mongoDelete( collection : String, filter : {}, ?onResult : Void -> Void ) {
        mongoRequest("/delete",{collection:collection,filter:filter},function(_) if( onResult != null ) onResult());
    }

    function mongoRequest( url, args : {}, onResult : Dynamic -> Void, ?onError : String -> Void ) {
        var rq = new haxe.Http(url);
        if( onError == null ) onError = displayError;
        rq.setParameter("args",haxe.Json.stringify(args));
        rq.onData = function(data) {
            var obj = try haxe.Json.parse(data) catch( e : Dynamic ) {
                onError(data);
                return;
            }
            onResult(obj);
        };
        rq.onError = onError;
        rq.request();
    }


}