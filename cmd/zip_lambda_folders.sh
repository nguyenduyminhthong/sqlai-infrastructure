cd ./src/lambda

for folder in */; do
    folder_name="${folder%/}"

    cd "$folder"
    zip -9 -r ../${folder_name}.zip .
    cd ..

done
