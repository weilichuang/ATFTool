package
{
	import flash.display.Sprite;
	import flash.display.StageAlign;
	import flash.display.StageScaleMode;
	import flash.events.Event;
	import flash.filesystem.File;
	import flash.filesystem.FileMode;
	import flash.filesystem.FileStream;
	
	import atftool.ATFGenerate;
	import atftool.GenerateInfo;
	import atftool.UIPanel;

	[SWF(width = 600, height = 500)]
	public class ATFTool extends Sprite
	{
		private var ui:UIPanel;

		private var generateInfo:GenerateInfo;

		private var generateAtf:ATFGenerate;

		private var exportFiles:Vector.<File>;

		private var totalFile:int;

		public function ATFTool()
		{
			stage.align = StageAlign.TOP_LEFT;
			stage.scaleMode = StageScaleMode.NO_SCALE;

			ui = new UIPanel();
			ui.addEventListener("Export", onExport);
			ui.addEventListener(UIPanel.EVENT_LOAD_COMPLETE, onUILoadComplete);
			addChild(ui);

			generateAtf = new ATFGenerate();
			generateAtf.addEventListener(ATFGenerate.EVENT_GENERATE_COMPLETE, onGenerateComplete);
			generateAtf.addEventListener(ATFGenerate.EVENT_GENERATE_ERROR, onGenerateError);
		}
		
		protected function onUILoadComplete(event:Event):void
		{
			readConfig();
		}
		
		private function readConfig():void
		{
			var configFile:File = new File(File.applicationStorageDirectory.resolvePath("app.config").nativePath);
			if(configFile.exists)
			{
				var fs:FileStream = new FileStream();
				fs.open(configFile, FileMode.READ);
				
				var configTxt:String = fs.readUTFBytes(fs.bytesAvailable);
				fs.close();
				
				var configJson:Object = JSON.parse(configTxt);
				
				ui.readConfig(configJson);
			}
		}
		
		private function saveConfig():void
		{
			var data:Object = {};
			data.sourceDir = generateInfo.sourceDir;
			data.exportDir = generateInfo.exportDir;
			data.platform = generateInfo.platform;
			data.compress = generateInfo.compress;
			data.mips = generateInfo.mips;
			data.quality = generateInfo.quality;
			
			data.createMips = generateInfo.createMips;
			data.mipWidth = generateInfo.mipWidth;
			data.mipHeight = generateInfo.mipHeight;
			data.mipExt = generateInfo.mipExt;
			
			var json:String = JSON.stringify(data);
			
			var configFile:File = new File(File.applicationStorageDirectory.resolvePath("app.config").nativePath);
			
			var fs:FileStream = new FileStream();
			fs.open(configFile, FileMode.WRITE);
			fs.writeUTFBytes(json);
			fs.close();
		}

		protected function onGenerateError(event:Event):void
		{
			ui.updateProgress((totalFile - exportFiles.length), totalFile);
			if (exportFiles.length == 0)
			{
				ui.log("--------------导出完毕-------------------");
				ui.exportBtnEnabled = true;
			}
			else
			{
				generateAtf.generate(exportFiles.pop(), generateInfo, logCallBack);
			}
		}

		protected function onGenerateComplete(event:Event):void
		{
			ui.updateProgress((totalFile - exportFiles.length), totalFile);
			if (exportFiles.length == 0)
			{
				ui.log("--------------导出完毕-------------------");
				ui.exportBtnEnabled = true;
			}
			else
			{
				generateAtf.generate(exportFiles.pop(), generateInfo, logCallBack);
			}
		}

		/**
		 * 点击了导出按钮
		 */
		private function onExport(e:Event):void
		{
			ui.exportBtnEnabled = false;

			generateInfo = new GenerateInfo();
			generateInfo.sourceDir = ui.sourceDir;
			if (generateInfo.sourceDir.charAt(generateInfo.sourceDir.length - 1) == "\\")
			{
				generateInfo.sourceDir = generateInfo.sourceDir.substr(0, generateInfo.sourceDir.length - 1);
			}
			generateInfo.exportDir = ui.exportDir;
			if (generateInfo.exportDir.charAt(generateInfo.exportDir.length - 1) == "\\")
			{
				generateInfo.exportDir = generateInfo.exportDir.substr(0, generateInfo.exportDir.length - 1);
			}
			generateInfo.platform = ui.platform;
			generateInfo.compress = ui.compress;
			generateInfo.mips = ui.mips;
			generateInfo.quality = ui.quality;
			generateInfo.createMips = ui.createMips;
			generateInfo.mipWidth = ui.mipWidth;
			generateInfo.mipHeight = ui.mipHeight;
			generateInfo.mipExt = ui.mipExt;
			
			saveConfig();

			if (generateInfo.mipExt == "" || generateInfo.mipExt == null)
			{
				ui.log("缩略图后缀不能为空", 0xFF0000);
				return;
			}

			exportFiles = new Vector.<File>();
			ergodicDirectory(new File(generateInfo.sourceDir));

			totalFile = exportFiles.length;

			ui.clearLogs();

			if (exportFiles.length == 0)
			{
				ui.log("没有文件需要导出.", 0xFF0000);
				ui.exportBtnEnabled = true;
			}
			else
			{
				ui.log("开始导出ATF...");
				ui.log("总共选择了" + exportFiles.length + "个文件.");

				generateAtf.generate(exportFiles.pop(), generateInfo, logCallBack);
			}
		}

		/**
		 * 遍历文件夹
		 * */
		private function ergodicDirectory(file:File):void
		{
			var array:Array = file.getDirectoryListing();
			var f:File;
			var length:int = array.length;
			for (var i:int = 0; i < length; i++)
			{
				f = array[i];
				if (f.isDirectory && ui.converChilds)
				{
					createDir(f);
					ergodicDirectory(f);
				}
				else
				{
					//非指定格式图片，直接拷贝到新目录
					var ext:String = f.extension.toLocaleLowerCase();
					if (ext != "png" && ext != "jpg" && ext != "jpeg")
					{
						if (generateInfo.sourceDir != generateInfo.exportDir)
							copyFile(f);
					}
					else
					{
						exportFiles.push(f);
					}
				}
			}
		}

		/**创建文件夹*/
		private function createDir(file:File):void
		{
			var path:String = file.nativePath.replace(generateInfo.sourceDir, generateInfo.exportDir);
			var f:File = new File(path);
			if (!f.exists)
			{
				f.createDirectory();
			}
		}

		/**复制文件*/
		private function copyFile(file:File):void
		{
			var path:String = file.nativePath.replace(generateInfo.sourceDir, generateInfo.exportDir);
			var f:File = new File(path);
			if (!f.exists)
			{
				file.copyTo(f, true);
			}
		}

		private function logCallBack(text:String, color:uint = 0x0):void
		{
			ui.log(text, color);
		}
	}
}
