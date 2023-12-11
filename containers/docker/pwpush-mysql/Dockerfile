# pwpush-mysql

# Using universal image as a base for old non universal image
# this is for the transition phase since these old image will become obsolete
ARG BASEIMAGE=pwpush:latest
FROM $BASEIMAGE

# Insert end of support note to inform users while spinning up containers
RUN sed -i '5 a \
            echo "          ##########################################################################          "\n \
            echo "          ###                 !!END OF SUPPORT NOTIFICATION!!                    ###          "\n \
            echo "          ###            THIS IMAGE HAS REACHED END-OF-SUPPORT STATE.            ###          "\n \
            echo "          ###       THERE WILL BE NO MORE NEW FEATURES OR SECURITY UPDATES.      ###          "\n \
            echo "          ###        PLEASE MIGRATE TO THE NEW IMAGE AS SOON AS POSSIBLE.        ###          "\n \
            echo "          ###                                                                    ###          "\n \
            echo "          ###                      FOR MORE INFORMATION GOTO                     ###          "\n \
            echo "          ###            https://github.com/pglombardo/PasswordPusher            ###          "\n \
            echo "          ###                 !!END OF SUPPORT NOTIFICATION!!                    ###          "\n \
            echo "          ##########################################################################          "\n \
            ' ./containers/docker/pwpush/entrypoint.sh

# Setting database backend
ENV DATABASE_URL=mysql2://passwordpusher_user:passwordpusher_passwd@mysql:3306/passwordpusher_db
