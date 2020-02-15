pipeline {
    libraries{
     lib 'shlib'
}
   agent any
    tools {
        maven "Maven"   
    }          
    stages{
        stage('Hubot')
        {
            steps{
                deploy()
            }
        }
    }
    }
