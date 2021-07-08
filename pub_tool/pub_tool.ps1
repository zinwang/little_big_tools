
$draft_path=".`\drafts`\articles`\drafts`\"
$copy_path=".`\drafts`\articles`\copys`\"
$draft_image_path=".`\assets`\images`\"
$garbege_path=".`\drafts`\articles`\garbages`\"

$pub_post_path="..`\_posts`\"
$pub_image_path="..`\assets`\images`\"

$root_path="..`\"

$local_image_path=""



function Input-Time{
	$year=Get-Date -Format "yyyy"
	$month=Get-Date -Format "MM" 
	$date=Get-Date -Format "dd"

	$ans_defult_time=Read-Host "It is $year/$month/$date today.`nDo you want it to be the default publish time?(y/n)"
	if($ans_defult_time.ToLower() -eq "n"){
		while($true){
			$tmp_year=Read-Host "What's the scheduled publish year?([Enter] for $year)"
			if($tmp_year -eq ""){
				break
			}
			if($tmp_year -match "\b20[0-9]{2}\b"){
				$year=$tmp_year
				break
			}
			Write-Host "Warning: Wrong format of time!!"
		}
		while($true){
			$tmp_month=Read-Host "What's the scheduled publish month?([Enter] for $month)"
			if($tmp_month -eq ""){
				break
			}
			if($tmp_month -match "\b(0?[0-9]|1[012])\b"){
				$month=$tmp_month
				break
			}
			Write-Host "Warning: Wrong format of time!!"
		}
		while($true){
			$tmp_date=Read-Host "What's the scheduled publish date?([Enter] for $date)"
			if($tmp_date -eq ""){
				break
			}
			if($tmp_date -match "\b([0-9]|[012][0-9]|3[01])\b"){
				$date=$tmp_date
				break
			}
			Write-Host "Warning: Wrong format of time!!"
		}

	}
	if($month -match "\b0[1-9]\b"){
		$month=$month -replace "0", ""
	}
	if($date -match "\b0[1-9]\b"){
		$date=$date -replace "0", ""
	}

	return $year, $month, $date
}



function Choose-Post{
	param($target_path)
	while($true){
		Write-Host "`nHere are the posts:`n"
		$post_list = New-Object -TypeName System.Collections.ArrayList
		$idx=1
		ls $target_path | ForEach {
			Write-Host "($idx) $($_.BaseName)"
			$post_list.Add($($_.BaseName)) | out-null
			$idx=$idx+1
		}
		$ans_post_choice=Read-Host "`nPlease choose the post"
		if($ans_post_choice -match "([1-9]|[1-9][0-9]+)"){
			if($ans_post_choice -le $idx){
				break
			}
		}elseif(($ans_post_choice -eq "0") -or ($ans_post_choice -eq "")){
			return ""
		}
		Write-Host "Warnning: The answer is not in the options!!"
	}
	#Write-Host "$($post_list[$ans_post_choice-1])"
	return $($post_list[$ans_post_choice-1])

}



function Input-Title{
	$title=""
	while($true){
		$title=Read-Host "What is the title of the post?"
		if($title -ne ""){
			break
		}
	}
	return $title
}





function Create-Draft{
	Write-Host "Create a draft"

	# Time stamp
	$ret=Input-Time
	$year=$ret[0]
	$month=$ret[1]
	$date=$ret[2]

	# Title
	$title=Input-Title


	# Create the file and image directory
	$postname="$year-$month-$date-$title"
	
	while($true){
		#Write-Host $postname
    	$ans_yn_create_file=Read-Host "Do you want to create $postname.md ?(y/n)"
		if($ans_yn_create_file.ToLower() -eq "n"){
			return
		}
		if($ans_yn_create_file.ToLower() -eq "y"){
			if((Test-Path "$draft_path$postname.md") -or (Test-Path "$copy_path$postname.md")){
				Write-Host "$postname.md has existed!"
				return
			}elseif(Test-Path "$draft_image_path$postname"){
				Write-Host "$draft_image_path$postname has existed!"
				return
			}
			break
		}

    }

    New-Item -Path $draft_path -Name "$postname.md" -ItemType "file" -Value "---`ntitle: $Title`ncategories:`ntags:`n---"
    mkdir "$draft_image_path$postname"

	# Open the file
	& "$draft_path$postname.md"
}


function TakeDown-Post{
	param($parameter)
	$postname = $parameter[0]
	$storage_path=$parameter[1]
	if(!(Test-Path "$pub_post_path$postname.md")){
		Write-Host "Fatal: $postname is not published!!"
		return -1
	}

	mv "$copy_path$postname.md" "$storage_path$postname.md"
	try{
		rm "$pub_post_path$postname.md"
		rm "$pub_image_path$postname"
	}catch{
		return -1
	}

	return 0
}





function Operate_Changing_Postname{
	param($parameter) # flag : 0 for file, 1 for directory
	$parent_path=$parameter[0]
	$origin_postname=$parameter[1]
	$modified_postname=$parameter[2]
	$flag=$parameter[3]

	$origin_name=$origin_postname
	$modified_name=$modified_postname
	#Write-Host "$origin_name, $modified_name"
	if(!$flag){
		$origin_name+=".md"
		$modified_name+=".md"
	}
	if(!(Test-Path "$parent_path$origin_name")){
			Write-Host "Fatal: $parent_path$origin_name not exist!!"
			return
		}
	if($origin_name -ne $modified_name){
		mv "$parent_path$origin_name" "$parent_path$modified_name"
	}
}


function Modify-Postname{
	param($origin_postname)

	$year, $month, $date, $title=$origin_postname.split("-")
	$origin_title=$title
	while($true){
		$ans_yn_edit_time=Read-Host "Do you want to modify the time stamp of $origin_postname ?(y/n)"
		if($ans_yn_edit_time.ToLower() -eq "y"){
			$ret=Input-Time
			$year=$ret[0]
			$month=$ret[1]
			$date=$ret[2]
			break
		}elseif($ans_yn_edit_time.ToLower() -eq "n"){
			break
		}
	}

	while($true){
		$ans_yn_edit_title=Read-Host "Do you want to modify the title of $origin_postname ?(y/n)"
		if($ans_yn_edit_title.ToLower() -eq "y"){
			$title=Input-Title
			break
		}elseif($ans_yn_edit_title.ToLower() -eq "n"){
			break
		}
	}

	# Modify YAML Title

	$dash_found=0
	$txt=""
	cat "$draft_path$origin_postname.md" | ForEach {
		$_=$_.trim("`n`r")
		if($_ -eq "---"){
			$dash_found+=1
		}
		if(($_ -match "title:") -and ($dash_found -eq 1)){
			$_=$_ -replace "$origin_title", "$title"
		}
		$txt+=$_+"`n"
	
	}
	#Write-Host $txt
	$txt > "$draft_path$origin_postname.md"


    # Modify Filename 
	$modified_postname="$year-$month-$date-$title"

	Operate_Changing_Postname($draft_path,$origin_postname,$modified_postname,0)
	Operate_Changing_Postname($draft_image_path,$origin_postname,$modified_postname,1)
	return $modified_postname
}


function Publish-Post{
	
	param($postname)
	Write-Host "Publish a Post"

	# Create publish image directory
	if(!(Test-Path "$pub_image_path$postname")){
		mkdir "$pub_image_path$postname"
	}

	# Make copy
	cp "$draft_path$postname.md" "$copy_path$postname.md"

	# Publish in _posts
	mv "$draft_path$postname.md" "$pub_post_path$postname.md" -Force

	# Publish images
	ls "$draft_image_path$postname" |ForEach {
		cp "$draft_image_path$postname`\$_.Name" "$pub_image_path$postname`\$_.Name" -Force
	}

	Write-Host "Publish done!"

}




function Edit-Post{
	Write-Host "Edit a Post"

	while($true){
		Write-Host "(1) Modify Time Stamp or Title of A Draft"
		Write-Host "(2) Modify Time Stamp or Title of A Published Post"
		Write-Host "(3) Edit Content of A Draft"
		Write-Host "(4) Edit Content of A Published Post(Live Edit)"
		Write-Host "(5) Back"

		$ans_edit_choice=Read-Host "Which option do you want to operate?"

		if($ans_edit_choice -eq "1"){
			$origin_postname=Choose-Post($draft_path)
			if($origin_postname -eq ""){
				continue
			}
			Modify-Postname($origin_postname)
		}elseif($ans_edit_choice -eq "2"){
			$postname=Choose-Post($pub_post_path)
			if($postname -eq ""){
				continue
			}
			$takedown_ret=TakeDown-Post($postname,$draft_path)
			if($takedown_ret -eq -1){
				Write-Host "Fatal: Can not take down the post!!"
				continue
			}
			$modified_postname=Modify-Postname($postname)
			Publish-Post($modified_postname)

		}elseif($ans_edit_choice -eq "3"){
			$postname=Choose-Post($draft_path)
			if($postname -eq ""){
				continue
			}
			& "$draft_path$postname.md"
		}elseif($ans_edit_choice -eq "4"){
			$postname=Choose-Post($pub_post_path)
			if($postname -eq ""){
				continue
			}
			$takedown_ret=TakeDown-Post($postname,$draft_path)
			if($takedown_ret -eq -1){
				Write-Host "Fatal: Can not take down the post!!"
				continue
			}
			Start-Process -FilePath "$draft_path$postname.md"  -Wait
			Publish-Post($postname)
		}elseif($ans_edit_choice -eq "5"){
			return
		}



	}


}




function Preview-Post{
	Write-Host "Preview in Jekyll"
	cd $root_path
	#Start-Process "bundle" "exec jekyll serve" -wait
	cd "_draft"
}





function List-Articles{
	param($target_path)
	$idx=1
	ls $target_path | ForEach {
			Write-Host "($idx) $($_.BaseName)"
			$idx=$idx+1
		}
	return $idx-1
}


function Get-StatusList{
	# Published
	Write-Host "`n"
	$pub_num=List-Articles($pub_post_path)
	Write-Host "Published: $pub_num`n"

	# copy
	$copy_num=List-Articles($copy_path)
	Write-Host "Copy: $copy_num`n"


	#drafts
	$draft_num=List-Articles($draft_path)
	Write-Host "Draft: $draft_num`n"

}


function TakeDown-Published{
	$postname=Choose-Post("$pub_post_path")
	if($postname -eq ""){
		return
	}
	while($true){
		$ans_yn_store_draft=Read-Host "Do you want to store the post as a draft?`nIf no, it will be in $garbege_path(y/n)"
		$place="drafts directory"
		if($ans_yn_store_draft.ToLower() -eq "y"){
			$takedown_ret=TakeDown-Post($postname,$draft_path)
		}elseif($ans_yn_store_draft.ToLower() -eq "n"){
			if(!(Test-Path "$garbege_path")){
				mkdir $garbege_path
			}
			$takedown_ret=TakeDown-Post($postname,$garbege_path)
			$place="garbeges directory"
		}
		if($takedown_ret -eq 0){
			Write-Host "Taking $postname down done!`nIt is now in $place."
			break
		}elseif($takedown_ret -eq -1){
			break
		}
	}
}




function Update-Copys{
	ls $pub_post_path | ForEach {
		$pub_postname=$_.BaseName
		if(!(Test-Path "$copy_path$pub_postname.md")){
			cp "$pub_post_path$pub_postname.md" "$copy_path$pub_postname.md"

			if(!(Test-Path "$draft_image_path$pub_postname")){
				mkdir "$draft_image_path$pub_postname"
			}
			ls "$pub_image_path$pub_postname" | ForEach{
				cp "$pub_image_path$pub_postname`\$_.Name" "$draft_image_path$pub_postname"
			}

		}

	}

}



function Check-Categories{
	$cat_list=New-Object -TypeName System.Collections.ArrayList
	$idx=1
	Write-Host "`n"
	ls "$copy_path" | ForEach {
		$cflag=0
		cat "$copy_path$_" | Select -first 15  | ForEach{
			if($_ -match "categories:"){
				$cflag=1
			}
			if(($cflag -eq 1) -and ($_ -match "-[\sA-Za-z0-9]")){
				$ctg= $($_ -replace "-","").trimstart().trimend()
				if(!($cat_list.Contains($cat))){
					$cat_list.Add($ctg) | out-null
					Write-Host "($idx) $ctg"
					$idx+=1
				}
			}
			if($_ -match "tags:"){
				$cflag=0
			}
		}
	}
	Write-Host "`nCategories: $($idx-1)"

}



function Get-FileName($target_path) {
  [System.Reflection.Assembly]::LoadWithPartialName("System.windows.forms") | Out-Null
  $OpenFileDialog = New-Object System.Windows.Forms.OpenFileDialog

  $OpenFileDialog.initialDirectory = $target_path

  $OpenFileDialog.filter = "Images(*.png;*.jpg;*.jpeg;*.bmp;*.svg;*.tiff;*.webp;*.gif)|*.png;*.jpg;*.jpeg;*.bmp;*.svg;*.tiff;*.webp;*.gif|All files(*.*)|*.*"
  

  $OpenFileDialog.ShowDialog((New-Object System.Windows.Forms.Form -Property @{TopMost = $true })) | Out-Null

  return $OpenFileDialog.filename, $OpenFileDialog.safefilename
}





function Add-ImageMaterial{
	$postname=Choose-Post("$draft_path")
	if($postname -eq ""){
		return
	}
	$new_img_path, $new_img_name=Get-FileName($local_image_path)
	if($new_img_path -eq ""){
		return
	}
	#Write-Host $new_img_name

	$new_draft_img="$draft_image_path$postname`\$new_img_name"
	$idx=1
	$tmp_file=$new_draft_img
	while($true){
		if(Test-Path $tmp_file){
			$tmp_file=".$($new_draft_img.split(".")[1])($idx).$($new_draft_img.split(".")[2])"
		}else{
			break
		}
		$idx+=1
	}
	$new_draft_img=$tmp_file
	Write-Host "$new_draft_img Added!`nYou can use it with ![$new_draft_img](..`\..`\.$new_draft_img)"
	cp $new_img_path $new_draft_img

}












# Begin

Write-Host "Tech Blog Publish tool"

Update-Copys

while($true){
	# main menu
	Write-Host "`n-----------------------------------------------------------------`n"

	Write-Host "(1) Publish Status"
	Write-Host "(2) Create A draft"
	Write-Host "(3) Edit A Post"
	Write-Host "(4) Publish A Post"
	Write-Host "(5) Take Down A Post"
	Write-Host "(6) Preview in Jekyll"
	Write-Host "(7) Update Copys"
	Write-Host "(8) Check Published Categories"
	Write-Host "(9) Add Material to A Draft Image Pool"
	Write-Host "(10) Exit"

	$ans_main_menu = Read-Host "Please choose the operation you want to excute"
	if($ans_main_menu -eq 10){
		exit
	}elseif($ans_main_menu -eq 1){
		Get-StatusList
	}elseif($ans_main_menu -eq 2){
		Create-Draft
	}elseif($ans_main_menu -eq 3){
		Edit-Post
	}elseif($ans_main_menu -eq 4){
		$postname=Choose-Post($draft_path)
		if($postname -eq ""){
			continue
		}
		Publish-Post($postname)
	}elseif($ans_main_menu -eq 5){
		TakeDown-Published
	}elseif($ans_main_menu -eq 6){
		Preview-Post
	}elseif($ans_main_menu -eq 7){
		Update-Copys
	}elseif($ans_main_menu -eq 8){
		Check-Categories
	}elseif($ans_main_menu -eq 9){
		Add-ImageMaterial
	}
}
