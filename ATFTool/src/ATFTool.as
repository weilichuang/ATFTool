package
{
	import flash.display.Sprite;
	import flash.display.StageAlign;
	import flash.display.StageScaleMode;
	import flash.events.Event;
	import flash.filesystem.File;

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
			addChild(ui);

			generateAtf = new ATFGenerate();
			generateAtf.addEventListener(ATFGenerate.EVENT_GENERATE_COMPLETE, onGenerateComplete);
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
			generateInfo.exportDir = ui.exportDir;
			generateInfo.platform = ui.platform;
			generateInfo.compress = ui.compress;
			generateInfo.mips = ui.mips;
			generateInfo.quality = ui.quality;
			generateInfo.createMips = ui.createMips;
			generateInfo.mipWidth = ui.mipWidth;
			generateInfo.mipHeight = ui.mipHeight;
			generateInfo.mipExt = ui.mipExt;

			if (generateInfo.mipExt == "" || generateInfo.mipExt == null)
			{
				ui.log("缩略图后缀不能为空\n");
				return;
			}

			exportFiles = new Vector.<File>();
			ergodicDirectory(new File(generateInfo.sourceDir));

			totalFile = exportFiles.length;

			ui.clearLogs();

			if (exportFiles.length == 0)
			{
				ui.log("没有文件需要导出.\n");
				ui.exportBtnEnabled = true;
			}
			else
			{
				ui.log("开始导出ATF...\n");
				ui.log("总共选择了" + exportFiles.length + "个文件.\n");

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
					if (f.extension.toLocaleLowerCase() != "png" && f.extension.toLocaleLowerCase() != "jpg" && f.extension.toLocaleLowerCase() != "jpeg")
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

		private function logCallBack(text:String):void
		{
			ui.log(text);
		}
	}
}
